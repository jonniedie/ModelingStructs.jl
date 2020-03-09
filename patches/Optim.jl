using Optim

# I made a pull request for this change to be made in Optim. We'll see where that goes. If
#   it doesn't get merged, I'll have to make Optim a dependency and put this in src.
function Optim.initial_state(method::IPNewton, options, d::TwiceDifferentiable, constraints::TwiceDifferentiableConstraints, initial_x::ModelingStruct{T}) where T
    # Check feasibility of the initial state
    mc = Optim.nconstraints(constraints)
    constr_c = Array{T}(undef, mc)
    # TODO: When we change to `value!` from NLSolversBase instead of c!
    # we can also update `initial_convergence` for ConstrainedOptimizer in interior.jl
    constraints.c!(constr_c, initial_x)
    if !Optim.isinterior(constraints, initial_x, constr_c)
        @warn("Initial guess is not an interior point")
        Base.show_backtrace(stderr, backtrace())
        println(stderr)
    end
    # Allocate fields for the objective function
    n = length(initial_x)
    g = similar(initial_x)
    s = similar(initial_x)
    f_x_previous = NaN
    f_x, g_x = Optim.value_gradient!(d, initial_x)
    g .= g_x # needs to be a separate copy of g_x
    H = Matrix{T}(undef, n, n)
    Hd = Vector{Int8}(undef, n)
    Optim.hessian!(d, initial_x)
    copyto!(H, Optim.hessian(d))

    # More constraints
    constr_J = Array{T}(undef, mc, n)
    gtilde = copy(g)
    constraints.jacobian!(constr_J, initial_x)
    μ = T(1)
    bstate = Optim.BarrierStateVars(constraints.bounds, initial_x, constr_c)
    bgrad = copy(bstate)
    bstep = copy(bstate)
    # b_ls = BarrierLineSearch(similar(constr_c), similar(bstate))
    b_ls = Optim.BarrierLineSearchGrad(copy(constr_c), copy(constr_J), copy(bstate), copy(bstate))

    state = Optim.IPNewtonState(
        copy(initial_x), # Maintain current state in state.x
        f_x, # Store current f in state.f_x
        copy(initial_x), # Maintain previous state in state.x_previous
        g, # Store current gradient in state.g (TODO: includes Lagrangian calculation?)
        T(NaN), # Store previous f in state.f_x_previous
        H,
        0,    # will be replaced
        Hd,
        similar(initial_x), # Maintain current x-search direction in state.s
        μ,
        μ,
        T(NaN),
        T(NaN),
        bstate,
        bgrad,
        bstep,
        constr_c,
        constr_J,
        T(NaN),
        Optim.@initial_linesearch()..., # Maintain a cache for line search results in state.lsr
        b_ls,
        gtilde,
        0)

    Hinfo = (state.H, Optim.hessianI(initial_x, constraints, 1 ./ bstate.slack_c, 1))
    Optim.initialize_μ_λ!(state, constraints.bounds, Hinfo, method.μ0)
    Optim.update_fg!(d, constraints, state, method)
    Optim.update_h!(d, constraints, state, method)

    state
end
