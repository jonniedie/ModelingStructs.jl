const BroadMod = Broadcast.Broadcasted{Broadcast.ArrayStyle{ModelingStruct}}

Base.BroadcastStyle(::Type{<:ModelingStruct}) = Broadcast.ArrayStyle{ModelingStruct}()

# Goes through fields and reattaches views to new vector
function _review(v, ms::ModelingStruct{T,V,K,P}) where {T,V,K,P}
    tup = map(x -> _review(v, x), _structure(ms))
    return ModelingStruct(v, NamedTuple{K}(tup), Val(false))
end
_review(v, a::AbstractVector) = map(x -> _review(v, x), a)
_review(v::A, r::SubArray) where {A} = view(v, r.indices[1])

# Create uninitialized ModelingStruct at new memory location
Base.similar(ms::ModelingStruct) = _review(similar(_data(ms)), ms)
Base.similar(ms::ModelingStruct, ::Type{T}) where {T} = _review(similar(_data(ms),T), ms)
Base.similar(bc::BroadMod, ::Type{T}) where T = similar(bc.args[1], T)

# Needed for usage with LAPACK. Stolen from:
#   https://github.com/JuliaDiffEq/LabelledArrays.jl/blob/master/src/larray.jl
function Base.unsafe_convert(::Type{Ptr{T}}, ms::ModelingStruct{T}) where T
    return Base.unsafe_convert(Ptr{T}, _data(ms))
end

# Conversion to NamedTuple (note, does not preserve numeric types of original NamedTuple)
function _namedtuple(ms::ModelingStruct{T,V,K}) where {T,V,K}
    data = []
    for key in K
        val = getproperty(ms, key) |> _namedtuple
        push!(data, key => val)
    end
    return (; data...)
end
_namedtuple(v::AbstractVector) = _namedtuple.(v)
_namedtuple(x) = x

Base.convert(::Type{NamedTuple}, x::ModelingStruct) = _namedtuple(x)
Base.NamedTuple(x::ModelingStruct) = _namedtuple(x)
