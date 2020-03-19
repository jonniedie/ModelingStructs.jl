"""
    ms = ModelingStruct{T}(nt::NamedTuple) where {T}

A mutable struct-like data type with homogeneous data type `T` that can be accessed like a
    vector or a struct. Useful for modeling tasks such as differential equations or
    mathematical optimization that operate internally on data as a flat vector while calling
    user functions that could often be better expressed if the data was a named tuple.
    For a more convenient constructor, see `mstruct`.

# Examples

```julia-repl
julia> c = (a=2, b=[1, 2]);

julia> p = (a=1, b=[2, 1, 4], c=c)

julia> ms = ModelingStruct{Float32}(p)
ModelingStruct(a = 1.0f0, b = Float32[2.0, 1.0, 4.0], c = (a = 2.0f0, b = Float32[1.0, 2.0]))

julia> ms.c.a = 4; ms
ModelingStruct(a = 1.0f0, b = Float32[2.0, 1.0, 4.0], c = (a = 4.0f0, b = Float32[1.0, 2.0]))

julia> ms[5]
4.0f0
```
"""
struct ModelingStruct{T,V<:AbstractVector{T},K,P} <: DenseVector{T} where N
    data::V
    structure::NamedTuple{K,P}
    # The ::Val{false} means don't reattach the views, I'll change this later, probably
    function ModelingStruct(vect::V, nt::NamedTuple{K,P}, make_refs::Val{false}) where {T,V<:AbstractVector{T},K,P}
        return new{T,V,K,P}(vect, nt)
    end
end
function ModelingStruct(vect::AbstractVector{T}, nt::NamedTuple{K}) where {T,K}
    vals = values(nt)
    N = vals .|> recursive_length |> indices
    tup = map((val, n) -> attach(view(vect, n), val), vals, N)
    nt = NamedTuple{K}(tup)
    v = maybe_parent(vect)
    return ModelingStruct(v, nt, Val(false))
end
function ModelingStruct{T}(nt::NamedTuple{K}) where {T,K}
    return ModelingStruct(Vector{T}(undef,recursive_length(nt)), nt)
end
ModelingStruct(nt::NamedTuple) = ModelingStruct{Float64}(nt)
ModelingStruct{T}(; kwargs...) where T = ModelingStruct{T}((;kwargs...))
ModelingStruct(; kwargs...) = ModelingStruct{Float64}((;kwargs...))

# MStruct is a convenience alias for ModelingStruct
MStruct = ModelingStruct

function attach(v::AbstractVector, nt::NamedTuple)
    return ModelingStruct(v, nt)
end
function attach(v::AbstractVector{T}, a::AbstractVector{TT}) where {T,TT}
    # if !isconcretetype(eltype(a))
    #     types = typeof.(a)
    #     error("Vectors in ModelingStructs must be homogeneous, this one has types: \n", join(types, "\n"))
    # end
    N = recursive_length(a[1])
    views = [attach(view(v, 1:N), a[1])]
    idx_start = N+1
    for idx in 2:length(a)
        idx_end = idx_start + N - 1
        push!(views, attach(view(v, idx_start:idx_end), a[idx]))
        idx_start = idx_end+1
    end
    return views
end
function attach(v::AbstractVector{T}, a::AbstractVector{<:N}) where {T,N<:Number}
    v .= a
    return @view v[:]
end
function attach(v::AbstractArray{T}, a::Number) where T
    v[1] = a
    return view(v, 1)
end
