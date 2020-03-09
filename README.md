# ModelingStructs

 Vectors that can be accessed like arbitrarily nested structs.

## Usage
```ModelingStructs``` can be instantiated with the ```mstruct``` function. The default argument
type is a Float64, but can be set via the first positional, non-keyword argument to ```mstruct```
.

```julia
using ModelingStructs

c = (a=2, b=[1, 2])
ms = mstruct(Float32, a=1, b=[2, 1, 4], c=c)
```

returns a

```julia
ModelingStruct{Float32}(a = 1.0f0, b = Float32[2.0, 1.0, 4.0], c = (a = 2.0f0, b = Float32[1.0, 2.0]))
```

that can be accessed like a mutable struct

```julia
julia> ms.c.a
2.0

julia> ms.c.b[1] = 200
julia> ms
ModelingStruct{Float32}(a = 1.0f0, b = Float32[2.0, 1.0, 4.0], c = (a = 2.0f0, b = Float32[200.0, 2.0]))
```

or like a flat array

```julia
julia> ms[6]
200.0

julia> collect(ms)
7-element Array{Float32,1}:
   1.0
   2.0
   1.0
   4.0
   2.0
 200.0
   2.0

julia>  foreach(x -> println(x^2), ms)
1.0
4.0
1.0
16.0
4.0
40000.0
4.0
```

## What is this useful for?
```ModelingStructs``` are useful for composing models together on the fly. The main targets are differential equations and optimization, but really anything that requires flat vectors is fair game (as long as it is written in Julia all the way down).

### Differential equation example
Example taken from:
https://github.com/JuliaDiffEq/ModelingToolkit.jl/issues/36#issuecomment-536221300
```julia
using ModelingStructs
using DifferentialEquations

MStruct = Union{ModelingStruct, ModelingStructs.ViewingNamedTuple}

function lorenz!(du, u::MStruct, p, t)
    du.x = p.σ*(u.y - u.x)
    du.y = u.x*(p.ρ - u.z) - u.y - p.f
    du.z = u.x*u.y - p.β*u.z
    return nothing
end
function lorenz!(du, u, p, t)
    du[1] = p.σ*(u[2] - u[1])
    du[2] = u[1]*(p.ρ - u[3]) - u[2] - p.f
    du[3] = u[1]*u[2] - p.β*u[3]
    return nothing
end

function lotka!(du, u::MStruct, p, t)
    du.x =  p.α*u.x - p.β*u.x*u.y + p.f
    du.y = -p.γ*u.y + p.δ*u.x*u.y
    return nothing
end
function lotka!(du, u, p, t)
    du[1] =  p.α*u[1] - p.β*u[1]*u[2] + p.f
    du[2] = -p.γ*u[2] + p.δ*u[1]*u[2]
    return nothing
end

function composed!(du, u::MStruct, p, t)
    lorenz!(du.lorenz, u.lorenz, (β=p.β, f=u.lotka.x, p.lorenz...), t)
    lotka!(  du.lotka,  u.lotka, (β=p.β, f=u.lorenz.x, p.lotka...), t)
    return nothing
end
function composed!(du, u, p, t)
    lorenz, lotka = u[1:3], u[4:5]
    lorenz!(view(du, 1:3), lorenz, (β=p.β, f=lotka[1], p.lorenz...), t)
    lotka!(view(du, 4:5),  lotka, (β=p.β, f=lorenz[1], p.lotka...), t)
    return nothing
end


lorenz_p = (σ=10.0, ρ=28.0)
lorenz_ic = (x=0.0, y=0.0, z=0.0)

lotka_p = (α=1.0, γ=1.1, δ=0.5)
lotka_ic = (x=1.0, y=1.0)

comp_p = (β=8/3, lorenz=lorenz_p, lotka=lotka_p)
comp_ic = mstruct(lorenz=lorenz_ic, lotka=lotka_ic)

flat_ic = [lorenz_ic.x, lorenz_ic.y, lorenz_ic.z, lotka_ic.x, lotka_ic.y]

prob = ODEProblem(composed!, comp_ic, (0.0, 20.0), comp_p)
sol = solve(prob, Tsit5())
```

Notice how cleanly the ```composed!``` function can unpack parameters and initial conditions, pass variables from one function to another, and maintain top-level shared parameters. No array index juggling in sight. This is especially useful for large models as it becomes harder to keep track top-level model array position when adding new or deleting old components from the model. We could go further and compose ```composed!``` with other components ad (practically) infinitum with no mental bookkeeping.
