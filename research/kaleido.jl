
# struct MStruct{K,T} <: AbstractVector{T}
#     data::K
#     vect::Vector{PropertyLens}
# end

macro MStruct(name, syms...)
    s = Symbol[]
    t = []
    for sym in syms
        if sym isa Symbol
            push!(s, sym)
            push!(t, :T)
        elseif sym isa Expr
            if sym.head == :(::)
                push!(s, sym.args[1])
                push!(t, Meta.parse(string(sym.args[2])*"{T}"))
            else
                error("Invalid type signature: $sym")
            end
        end
    end
    eval(quote $name{T} = NamedViewVector{T, ($s...,), Tuple{$(t...)}} end)
end


function f(ẋ, x, p, t)
    ẋ.a = -x.a + p*x.b
    ẋ.b = -x.b
    return nothing
end

function g(ẋ, x, p, t)
    f(ẋ.f, x.f, x.a, t)
    ẋ.a = -x.f.a + x.f.b
    return nothing
end
