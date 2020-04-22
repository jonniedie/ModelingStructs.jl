
NOTE: Depreciated in favor of [ComponentArrays.jl](https://github.com/jonniedie/ComponentArrays.jl). Go there instead.

# ModelingStructs

 Mutable, named-tuple-ish things that act like vectors when they need to.

## Usage
```ModelingStructs``` can be instantiated with the ```MStruct``` alias as well. The default argument
type is a Float64, but can be customized via:

```julia
using ModelingStructs

c = (a=2, b=[1, 2])
ms = MStruct{Float32}(a=1, b=[2, 1, 4], c=c)
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
```ModelingStructs``` are useful for composing models together on the fly. The main targets are differential equations and optimization, but really anything that requires flat vectors is fair game.

### Differential equation example
This example uses ```@unpack``` from Parameters.jl for nice syntax. Example taken from:
https://github.com/JuliaDiffEq/ModelingToolkit.jl/issues/36#issuecomment-536221300
```julia
using ModelingStructs
using DifferentialEquations
using Parameters: @unpack


# Lorenz system
function lorenz!(D, u, (p, f), t)
    @unpack σ, ρ, β = p
    @unpack x, y, z = u
    
    D.x = σ*(y - x)
    D.y = x*(ρ - z) - y - f
    D.z = x*y - β*z
    return nothing
end

lorenz_p = (σ=10.0, ρ=28.0, β=8/3)
lorenz_ic = MStruct(x=0.0, y=0.0, z=0.0)


# Lotka-Volterra system
function lotka!(D, u, (p, f), t)
    @unpack α, β, γ, δ = p
    @unpack x, y, z = u
    
    D.x =  α*x - β*x*y + f
    D.y = -γ*y + δ*x*y
    return nothing
end

lotka_p = (α=2/3, β=4/3, γ=1.0, δ=1.0)
lotka_ic = MStruct(x=1.0, y=1.0)


# Composed Lorenz and Lotka-Volterra system
function composed!(D, u, p, t)
    @unpack lorenz, lotka = u
    
    lorenz!(D.lorenz, lorenz, (p.lorenz, lotka.x), t)
    lotka!(D.lotka, lotka, (p.lotka, lorenz.x), t)
    return nothing
end

comp_p = (lorenz=lorenz_p, lotka=lotka_p)
comp_ic = MStruct(lorenz=lorenz_ic, lotka=lotka_ic)


# Create and solve problem
prob = ODEProblem(composed!, comp_ic, (0.0, 20.0), comp_p)
sol = solve(prob, Tsit5())
```

Notice how cleanly the ```composed!``` function can pass variables from one function to another with no array index juggling in sight. This is especially useful for large models as it becomes harder to keep track top-level model array position when adding new or deleting old components from the model. We could go further and compose ```composed!``` with other components ad (practically) infinitum with no mental bookkeeping.

The main benefit, however, is now our differential equations are unit testable. Both ```lorenz``` and ```lotka``` can be run as their own ```ODEProblem``` with ```f``` set to zero to see the unforced response.

## Related Work
There are a few other packages that provide the same basic functionality as `ModelingStructs`. None (that I can tell) allow for nested structures, including fields with vectors of structures, which is important especially for composing differential equations together. It's possible that these can be used in conjunction with [RecursiveArrayTools](https://github.com/JuliaDiffEq/RecursiveArrayTools.jl) to get this functionality, but it seemed like that would be as much work as just writing this package from scratch, so I didn't bother.

[LabelledArrays](https://github.com/JuliaDiffEq/LabelledArrays.jl):
`LVector`s are the same basic idea, with similar construction by keyword or named tuple. Additionally, there is support for higher-dimensional `LArrays` and convenience macros for defining types. The main downside is they cannot be nested.

[StaticArrays](https://juliaarrays.github.io/StaticArrays.jl):
`FieldVector` is an abstract type that can be subtyped by custom user types. The benefit here is that allowing users to define their own custom struct allows users to take advantage of multiple dispatch more easily. The main downside is that the syntax for defining compatible `struct`s is slightly more cumbersome and boilerplatey.
