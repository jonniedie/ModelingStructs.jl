# This hasn't been submitted as a PR
NLSolversBase.x_of_nans(ms::ModelingStruct{T}, Tf=T) where T = fill!(similar(ms, Tf), Tf(NaN))
