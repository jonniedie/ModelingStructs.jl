using ModelingStructs
using DifferentialEquations


# Lorenz system
function lorenz!(du, u, p, t)
    du.x = p.σ*(u.y - u.x)
    du.y = u.x*(p.ρ - u.z) - u.y - p.f
    du.z = u.x*u.y - p.β*u.z
    return nothing
end

lorenz_p = (σ=10.0, ρ=28.0)
lorenz_ic = (x=0.0, y=0.0, z=0.0)


# Lotka-Volterra system
function lotka!(du, u, p, t)
    du.x =  p.α*u.x - p.β*u.x*u.y + p.f
    du.y = -p.γ*u.y + p.δ*u.x*u.y
    return nothing
end

lotka_p = (α=1.0, γ=1.1, δ=0.5)
lotka_ic = (x=1.0, y=1.0)


# Composed Lorenz and Lotka-Volterra system
function composed!(du, u, p, t)
    lorenz!(du.lorenz, u.lorenz, (β=p.β, f=u.lotka.x, p.lorenz...), t)
    lotka!(  du.lotka,  u.lotka, (β=p.β, f=u.lorenz.x, p.lotka...), t)
    return nothing
end

comp_p = (β=8/3, lorenz=lorenz_p, lotka=lotka_p)
comp_ic = mstruct(lorenz=lorenz_ic, lotka=lotka_ic)


# Create and solve problem
prob = ODEProblem(composed!, comp_ic, (0.0, 20.0), comp_p)
sol = solve(prob, Tsit5())
