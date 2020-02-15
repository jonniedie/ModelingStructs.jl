data(x) = getfield(x, :data)
vector(x) = getfield(x, :vector)


SingleView{T} = SubArray{T,0,Array{T,1},Tuple{Int64},true} where T

struct ViewingNamedTuple{K,T}
    data::NamedTuple{K,T}
end
ViewingNamedTuple(; kwargs...) = ViewingNamedTuple((; kwargs...))


Base.getproperty(vnt::ViewingNamedTuple, key::Symbol) = _getprop(getproperty(data(vnt), key)) #[1]

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
        val = getproperty(vnt, key)
        if val isa ViewingNamedTuple
            val = namedtuple(val)
        end
        push!(data, key => val)
    end
    return (; data...)
end

Base.promote_rule(::Type{ViewingNamedTuple}, ::Type{NamedTuple{K,T}}) where {K,T} = ViewingNamedTuple{K,T}
Base.convert(::Type{ViewingNamedTuple}, x::NamedTuple) =  ViewingNamedTuple(x)


function attached!(vect::Vector{T}, nt::NamedTuple) where {T}
    p = []
    for (key, val) in zip(keys(nt), values(nt))
        push!(p, key => attached!(vect, val))
    end
    return ViewingNamedTuple(; p...)
end
function attached!(vect::Vector{T}, arr::AbstractArray{A}) where {T, A}
    len = length(vect)
    v = [attached!(vect, arr[1])]
    for idx in 2:length(arr)
        push!(v, attached!(vect, arr[idx]))
    end
    return v
end
function attached!(vect::Vector{T}, val) where {T}
    push!(vect, convert(T, val))
    return @view vect[end]
end

function Base.show(io::IO, vnt::ViewingNamedTuple)
    show(io, namedtuple(vnt))
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
    print(io, "ViewingNamedTuple", K, T)
    return nothing
end


struct NamedViewVector{T,K,P} <: AbstractVector{T}
    data::ViewingNamedTuple{K,P}
    vector::Vector{T}
end
function NamedViewVector{T}(nt::NamedTuple) where {T}
    vector = T[]
    data = attached!(vector, nt) #[1]
    return NamedViewVector{T,typeof(data).parameters...}(data, vector)
end

Base.getproperty(nvv::NamedViewVector, key::Symbol) = getproperty(data(nvv), key)

Base.setproperty!(nvv::NamedViewVector, key::Symbol, val) = setproperty!(data(nvv), key, val)

Base.propertynames(nvv::NamedViewVector) = propertynames(data(nvv))

Base.similar(nvv::NamedViewVector{T}) where {T} = NamedViewVector{T}(namedtuple(data(nvv)))
Base.similar(nvv::NamedViewVector,::Type{T}) where {T} = NamedViewVector{T}(namedtuple(data(nvv)))

Base.getindex(nvv::NamedViewVector, i) = getindex(vector(nvv), i)

Base.setindex!(nvv::NamedViewVector, val, i) = setindex!(vector(nvv), val, i)
function Base.setindex!(nvv::NamedViewVector, val, ::Colon)
    for i in eachindex(nvv)
        setindex!(nvv, val, i)
    end
    return nothing
end
function Base.setindex!(nvv::NamedViewVector, val::AbstractArray, ::Colon)
    nvv .= val
    return nothing
end

Base.length(nvv::NamedViewVector) = length(getfield(nvv, :vector))

Base.size(nvv::NamedViewVector) = size(getfield(nvv, :vector))

Base.IndexStyle(nvv::NamedViewVector) = IndexLinear()

function Base.show(io::IO, nvv::NamedViewVector)
    show(io, data(nvv))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", nvv::NamedViewVector)
    print(io, "NamedViewVector")
    show(io, data(nvv))
    return nothing
end
