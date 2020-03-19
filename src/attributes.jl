Base.length(ms::ModelingStruct) = length(_data(ms))

Base.size(ms::ModelingStruct) = size(_data(ms))

Base.propertynames(ms::ModelingStruct{T,V,K}) where {T,V,K} = K
