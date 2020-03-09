module ModelingStructs

using Requires

include("types\\ViewingNamedTuple.jl")
include("types\\ModelingStruct.jl")
include("utilities.jl")

function __init__()
    # For some reason, this still puts out a warning that NLSolversBase isn't in the
    #   dependencies when Optim is being used. It works, but I'd rather not have the warning.
    @require NLSolversBase = "d41bc354-129a-5804-8e4c-c37616107c6c" include("..\\patches\\nlsolversbase.jl")
    @require Optim = "429524aa-4258-5aef-a3af-852621145aeb" include("..\\patches\\optim.jl")
end

export ModelingStruct, mstruct

end # module
