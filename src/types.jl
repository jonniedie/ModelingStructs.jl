data(x) = getfield(x, :data)
vector(x) = getfield(x, :vector)


SingleView{T} = SubArray{T,0,Array{T,1},Tuple{Int64},true} where T

struct ViewingNamedTuple{K,P}
    data::NamedTuple{K,P}
    ViewingNamedTuple(data::NamedTuple{K,P}) where {K,P} = new{K,P}(data)
end
# ViewingNamedTuple{K,P}(args...) where {K,P} = ViewingNamedTuple{K,P}(NamedTuple{K}(args))
ViewingNamedTuple(; kwargs...) = ViewingNamedTuple((; kwargs...))
# ViewingNamedTuple{K,P}(; kwargs...) where {K,P} = ViewingNamedTuple{K,P}(NamedTuple{K}(kwargs))

Base.propertynames(vnt::ViewingNamedTuple) = propertynames(data(vnt))

Base.getproperty(vnt::ViewingNamedTuple, key::Symbol) = _getprop(getproperty(data(vnt), key))

_getprop(elem::SingleView) = elem[1]
_getprop(elem) = elem

function Base.setproperty!(vnt::ViewingNamedTuple, key::Symbol, val)
    # d = getfield(vnt, :data)
    d = data(vnt)
    prop = getproperty(d, key)
    _setvalue!(prop, val)
    return nothing
end

# Need this function barrier for type stability
function _setvalue!(arr, val)
    arr[1] = val
    return nothing
end

Base.keys(vnt::ViewingNamedTuple) = keys(data(vnt))
Base.values(vnt::ViewingNamedTuple) = values(data(vnt))

function namedtuple(vnt::ViewingNamedTuple)
    data = []
    for key in keys(vnt)
        val = getproperty(vnt, key) |> namedtuple
        push!(data, key => val)
    end
    return (; data...)
end
namedtuple(v::AbstractVector) = namedtuple.(v)
namedtuple(x) = x

Base.promote_rule(::Type{ViewingNamedTuple}, ::Type{NamedTuple{K,P}}) where {K,P} = ViewingNamedTuple{K,P}
Base.convert(::Type{ViewingNamedTuple{K,P}}, x::NamedTuple) where {K,P} =  ViewingNamedTuple(NamedTuple{K,P}(x))


# function attached!(vect::Vector{T}, nt::NamedTuple{K,P}) where {T,K,P}
#     p = []
#     for (key, val) in zip(keys(nt), values(nt))
#         push!(p, key => attached!(vect, val))
#     end
#     return ViewingNamedTuple((; p...))
# end
function attached!(vect::Vector, nt::NamedTuple{K}) where {K}
    v = []
    for (key, val) in zip(keys(nt), values(nt))
        push!(v, attached!(vect, val))
    end
    return ViewingNamedTuple(NamedTuple{K}((v...,)))
end
function attached!(vect::Vector{T}, arr::AbstractArray{A}) where {T, A}
    len = length(vect)
    v = [attached!(vect, arr[1])]
    for idx in 2:length(arr)
        push!(v, attached!(vect, arr[idx]))
    end
    return v
end
function attached!(vect::Vector{T}, arr::AbstractArray{N}) where {T, N<:Number}
    newel = length(vect)+1
    push!(vect, T.(arr)...)
    return @view vect[newel:end]
end
function attached!(vect::Vector{T}, val) where {T}
    push!(vect, convert(T, val))
    return @view vect[end]
end

function Base.show(io::IO, vnt::ViewingNamedTuple)
    print(io, namedtuple(vnt))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", vnt::ViewingNamedTuple)
    print(io, "ViewingNamedTuple")
    show(io, namedtuple(vnt))
    return nothing
end
function Base.show(io::IO, ::Type{<:ViewingNamedTuple})
    print(io, "ViewingNamedTuple")
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ::Type{<:ViewingNamedTuple{K,T}}) where {K,T}
    print(io, "ViewingNamedTuple{", K, ", ", T, "}")
    return nothing
end


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

mstruct(type=Float64; kwargs...) = ModelingStruct{type}((;kwargs...))

function init_nt(::Type{<:NamedTuple{K,P}}) where {K,P}
    params = P.parameters
    v = []
    for param in params
        push!(v, undef_nt(param))
    end
end
init_nt(::Type{<:N}) where N<:Number = zero(N)

# default(::Type{T}) where T<:Number = zero(T)
# default(::Type{A{T}}) where {A<:AbstractArray, T<:Number} = A{T}(undef)


# function Base.convert(::Type{ModelingStruct{T,K,P}}, v::AbstractVector{S}) where {T,K,P,S}
#
# end

Base.getproperty(ms::ModelingStruct, key::Symbol) = getproperty(data(ms), key)

Base.setproperty!(ms::ModelingStruct, key::Symbol, val) = setproperty!(data(ms), key, val)

Base.propertynames(ms::ModelingStruct) = propertynames(data(ms))

# TODO: Make this so it doesn't have to make make a new named tuple
Base.similar(ms::N) where {N<:ModelingStruct} = N(namedtuple(data(ms)))
Base.similar(ms::ModelingStruct,::Type{T}) where {T} = ModelingStruct{T}(namedtuple(data(ms)))

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

Base.IndexStyle(ms::ModelingStruct) = IndexLinear()

function Base.show(io::IO, ms::ModelingStruct)
    show(io, data(ms))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ms::ModelingStruct)
    print(io, "ModelingStruct")
    show(io, data(ms))
    return nothing
end
