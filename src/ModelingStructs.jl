module ModelingStructs

using Requires

include("utils.jl")
include("MStruct.jl")
include("set_get.jl")
include("attributes.jl")
include("similar_convert.jl")
include("show.jl")

function __init__()
    @require Optim = "429524aa-4258-5aef-a3af-852621145aeb" include("../patches/optim.jl")
end

export ModelingStruct, MStruct

end # module
