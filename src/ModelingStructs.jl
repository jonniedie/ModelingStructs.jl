module ModelingStructs

using Requires

include("types.jl")

function __init__()
    @require NLSolversBase="d41bc354-129a-5804-8e4c-c37616107c6c" include("patches\\nlsolversbase.jl")
    @require Optim = "429524aa-4258-5aef-a3af-852621145aeb" include("patches\\optim.jl")
end

export ModelingStruct, mstruct

end # module
