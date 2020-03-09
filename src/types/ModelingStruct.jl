
"""
    ms = ModelingStruct{T}(nt::NamedTuple) where {T}

A mutable struct-like data type with homogeneous data type T that can be accessed like a
    vector or a struct. For a more convenient constructor, see `mstruct`.

# Examples

```julia-repl
julia> Polar = NamedTuple{(:r, :θ)};

julia> zpk_nt = (z=Polar.([(2,1), (3,2)]), p=Polar.([(5, 5)]), k=5)

julia> ms = ModelingStruct{Float64}(zpk_nt)
ModelingStruct(z = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 2.0, θ = 1.0), (r = 3.0, θ = 2.0)], p = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 5.0, θ = 5.0)], k = 5.0)

julia> ms.z[1].r = 20;

julia> ms
ModelingStruct(z = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 20.0, θ = 1.0), (r = 3.0, θ = 2.0)], p = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 5.0, θ = 5.0)], k = 5.0)
```
"""
struct ModelingStruct{T,K,P} <: AbstractVector{T}
    data::ViewingNamedTuple{K,P}
    vector::Vector{T}
end
function ModelingStruct{T}(nt::NamedTuple) where {T}
    vector = T[]
    data = attached!(vector, nt) #[1]
    return ModelingStruct{T,typeof(data).parameters...}(data, vector)
end
function ModelingStruct{T,K,P}(nt::NamedTuple) where {T,K,P}
    vector = T[]
    data = attached!(vector, nt)
    return ModelingStruct{T,K,P}(data, vector)
end
ModelingStruct(ms::ModelingStruct) = deepcopy(ms)
# function ModelingStruct{K,P}(v::Vector{<:T}) where {T,K,P}
#     ms = ModelingStruct{T,K,P}
#     data = attached!(v, )
# end

"""
    ms = mstruct(type=Float64; kwargs...)

Convenience constructor for creating ModelingStructs.

# Examples
```julia-repl
julia> using ModelingStructs

julia> c = (a=2, b=[1, 2]);

julia> ms = mstruct(Float32, a=1, b=[2, 1, 4], c=c)
ModelingStruct(a = 1.0f0, b = Float32[2.0, 1.0, 4.0], c = (a = 2.0f0, b = Float32[1.0, 2.0]))
```

```julia-repl
julia> Polar = NamedTuple{(:r, :θ)};

julia> ms = mstruct(z=Polar.([(2,1), (3,2)]), p=Polar.([(5, 5)]), k=5)
ModelingStruct(z = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 2.0, θ = 1.0), (r = 3.0, θ = 2.0)], p = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 5.0, θ = 5.0)], k = 5.0)

julia> ms.z[1].r = 20;

julia> ms
ModelingStruct(z = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 20.0, θ = 1.0), (r = 3.0, θ = 2.0)], p = NamedTuple{(:r, :θ),Tuple{Float64,Float64}}[(r = 5.0, θ = 5.0)], k = 5.0)
```
"""
mstruct(type=Float64; kwargs...) = ModelingStruct{type}((;kwargs...))

function init_nt(::Type{<:NamedTuple{K,P}}) where {K,P}
    params = P.parameters
    v = []
    for param in params
        push!(v, undef_nt(param))
    end
end
init_nt(::Type{<:N}) where N<:Number = zero(N)

Base.getproperty(ms::ModelingStruct, key::Symbol) = getproperty(data(ms), key)

Base.setproperty!(ms::ModelingStruct, key::Symbol, val) = setproperty!(data(ms), key, val)

Base.propertynames(ms::ModelingStruct) = propertynames(data(ms))

# TODO: Make this so it doesn't have to make make a new named tuple
Base.similar(ms::N) where {N<:ModelingStruct} = N(namedtuple(data(ms)))
Base.similar(ms::ModelingStruct,::Type{T}) where {T} = ModelingStruct{T}(namedtuple(data(ms)))

Base.IndexStyle(ms::ModelingStruct) = IndexLinear()

Base.getindex(ms::ModelingStruct, i) = getindex(vector(ms), i)

Base.setindex!(ms::ModelingStruct, val, i) = setindex!(vector(ms), val, i)
function Base.setindex!(ms::ModelingStruct, val, ::Colon)
    for i in eachindex(ms)
        setindex!(ms, val, i)
    end
    return nothing
end
function Base.setindex!(ms::ModelingStruct, val::AbstractArray, ::Colon)
    ms .= val
    return nothing
end

Base.length(ms::ModelingStruct) = length(getfield(ms, :vector))

Base.size(ms::ModelingStruct) = size(getfield(ms, :vector))

function Base.show(io::IO, ms::ModelingStruct)
    show(io, data(ms))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ms::ModelingStruct)
    print(io, "ModelingStruct")
    show(io, data(ms))
    return nothing
end
