function Base.show(io::IO, ms::ModelingStruct{T,V,K}) where {T,V,K}
    key = K[1]
    print(io, "($key = $(ms[key])")
    for idx in 2:length(K)
        key = K[idx]
        print(io, ", $key = $(ms[key])")
    end
    print(io, ")")
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ms::ModelingStruct{T}) where T
    print(io, "ModelingStruct{" , T, "}")
    show(io, ms)
    return nothing
end
function Base.show(io::IO, a::AbstractVector{<:T}) where T<:ModelingStruct
    elem = a[1]
    print(io, "[$elem")
    for idx in 2:length(a)
        print(io, ", $(a[idx])")
    end
    print(io, "]")
    return nothing
end
