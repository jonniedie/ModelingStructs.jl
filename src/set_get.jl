const SingleView{A,T} = SubArray{T,0,A,Tuple{Int64},true}

# Access to underlying data
_structure(x) = getfield(x, :structure)
_data(x) = getfield(x, :data)

# Need these function barriers for type stability
Base.@propagate_inbounds _getprop(elem::SingleView) = elem[]
Base.@propagate_inbounds _getprop(elem) = elem

function _setvalue!(arr, val)
    arr[] = val
    return nothing
end

Base.@propagate_inbounds Base.getproperty(ms::ModelingStruct, key::Symbol) = _getprop(getproperty(_structure(ms), key))

Base.@propagate_inbounds function Base.setproperty!(ms::ModelingStruct, key::Symbol, val)
    d = _structure(ms)
    prop = getproperty(d, key)
    _setvalue!(prop, val)
    return nothing
end

Base.getindex(ms::ModelingStruct, i) = getindex(_data(ms), i)
Base.getindex(ms::ModelingStruct, key::Union{Symbol, String}) = getproperty(ms, Symbol(key))

Base.setindex!(ms::ModelingStruct, val, i...) = setindex!(_data(ms), val, i...)
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
Base.setindex!(ms::ModelingStruct, val, key::Union{Symbol, String}) = setproperty!(ms, Symbol(key), val)
