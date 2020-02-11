# NamedViewVectors

 Vectors that can be accessed like arbitrarily nested structs.

## Usage
```NamedViewVectors``` can be instantiated with named tuples.

```julia
using NamedViewVectors

c = (a=2, b=[1, 2])
p = (a=1, b=[2, 1, 4], c=c)
nvv = NamedViewVector{Float64}(p)
```

returns a

```julia
NamedViewVector{Float64}(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [1.0, 2.0]))
```

that can be accessed like a mutable struct

```julia
julia> nvv.c.a
2.0

julia> nvv.c.b[1] = 200
julia> nvv
NamedViewVector(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [200.0, 2.0]))
```

or like a flat array

```julia
julia> nvv[6]
200.0

julia> collect(nvv)
7-element Array{Float64,1}:
   1.0
   2.0
   1.0
   4.0
   2.0
 200.0
   2.0

julia>  foreach(x -> println(x^2), nvv)
1.0
4.0
1.0
16.0
4.0
40000.0
4.0
```

## What is this useful for?
```NamedViewVectors``` are useful for composing models together on the fly. The main targets are differential equations and optimization, but really anything that requires flat vectors is fair game (as long as it is written in Julia all the way down).

### Differential equation example
Example taken from:
https://github.com/JuliaDiffEq/ModelingToolkit.jl/issues/36#issuecomment-536221300
```julia
using NamedViewVectors
using DifferentialEquations

function lorenz!(du, u, (p, f), t)
    du.x = p.σ*(u.y - u.x)
    du.y = u.x*(p.ρ - u.z) - u.y + f
    du.z = u.x*u.y - p.β*u.z
    return nothing
end

function lotka!(du, u, (p, f), t)
    du.x =  p.α*u.x - p.β*u.x*u.y + f
    du.y = -p.γ*u.y + p.δ*u.x*u.y
    return nothing
end

function composed!(du, u, p, t)
    lorenz!(du.lorenz, u.lorenz, ((β=p.β, p.lorenz...), u.lotka.x), t)
    lotka!(du.lotka, u.lotka, ((β=p.β, p.lotka...), u.lorenz.x), t)
    return nothing
end

lorenz_p = (σ=1.0, ρ=1.0)
lotka_p = (α=1.0, γ=3.1, δ=0.5)
p = (β=1.0, lorenz=lorenz_p, lotka=lotka_p)

tspan = (0.0, 20.0)
lorenz_ic = (x=0.0, y=0.0, z=0.0)
lotka_ic = (x=1.0, y=1.0)

u₀ = NamedViewVector{Float64}((lorenz=lorenz_ic, lotka=lotka_ic))

prob = ODEProblem(composed!, u₀, tspan, p)
sol = solve(prob, Tsit5())
```

Notice how cleanly the ```composed!``` function can unpack parameters and initial conditions, pass variables from one function to another, and maintain top-level shared parameters. No array index juggling in sight. This is especially useful for large models as it becomes harder to keep track top-level model array position when adding new or deleting old components from the model. We could go further and compose ```composed!``` with other components ad (practically) infinitum with no mental bookkeeping.
