using Setfield
using Setfield: IndexLens, PropertyLens, ComposedLens

struct Lens!{L <:Lens} <: Lens
    pure::L
end

Setfield.get(o, l::Lens!) = Setfield.get(o, l.pure)
function Setfield.set(o, l::Lens!{<: ComposedLens}, val)
    o_inner = get(o, l.pure.outer)
    set(o_inner, Lens!(l.pure.inner), val)
end
function Setfield.set(o, l::Lens!{PropertyLens{prop}}, val) where {prop}
    setproperty!(o, prop, val)
    o
end
function Setfield.set(o, l::Lens!{<:IndexLens}, val) where {prop}
    o[l.pure.indices...] = val
    o
end
#
#  struct ModellingStruct{K,T} <: AbstractVector{T}
#      data::K
#      vect::Vector{Lens!}
#      function ModellingStruct{T}(data::K) where {K,T}
#          data = deepcopy(data)
#          vect = []
#          for fname in propertynames(data)
#              lens = Lens!(PropertyLens{fname}())
#              push!(vect, lens)
#              set(data, lens, convert(T, get(data, lens)))
#          end
#          return new{K,T}(data, vect)
#      end
#  end

 struct ModellingStruct{K,T} <: AbstractVector{T}
     data::K
     vect::Vector{PropertyLens}
     function ModellingStruct{T}(data::K) where {K,T}
         data = deepcopy(data)
         vect = PropertyLens[]
         for fname in propertynames(data)
             lens = PropertyLens{fname}()
             push!(vect, lens)
             set(data, lens, convert(T, get(data, lens)))
         end
         return new{K,T}(data, vect)
     end
 end


# Hidden field access
data(ms::ModellingStruct) = getfield(ms, :data)
vect(ms::ModellingStruct) = getfield(ms, :vect)



function Setfield.get(obj, l::PropertyLens{field}) where {field}
    getfield(obj, field)
end

# Overload base methods
Base.size(ms::ModellingStruct) = size(vect(ms))

Base.getindex(ms::ModellingStruct, idx...) = get(data(ms), vect(ms)[idx...])

Base.setindex!(ms::ModellingStruct{K,T}, val, idx...) where {K,T} = set(data(ms), Lens!(vect(ms)[idx...]), T(val))

Base.getproperty(ms::ModellingStruct, sym::Symbol) = get(ms, @lens(_.data) ∘ PropertyLens{sym}())

Base.setproperty!(ms::ModellingStruct, sym::Symbol, val) = set(ms, @lens(_.data) ∘ PropertyLens{sym}(), val)

# Base.propertynames(ms::ModellingStruct) = propertynames(data(ms))
