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
