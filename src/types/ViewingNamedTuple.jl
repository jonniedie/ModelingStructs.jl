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

# attached! is used for attaching ViewingNamedTuples to vectors in ModelingStructs
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
