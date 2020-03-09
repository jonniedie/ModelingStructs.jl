using Optim
using ModelingStructs

include("..\\patches\\Optim.jl")
include("..\\patches\\NLSolversBase.jl")

rosen(u) = (1.0 - u.x)^2 + 100.0 * (u.y - u.x^2)^2
u₀ = mstruct(x=0, y=0)

lb = mstruct(x=-0.5, y=-0.5)
ub = mstruct(x=0.5, y=0.5)


df = TwiceDifferentiable(rosen, u₀; autodiff=:forward)
dfc = TwiceDifferentiableConstraints(lb, ub)

val = optimize(df, dfc, u₀, IPNewton())
