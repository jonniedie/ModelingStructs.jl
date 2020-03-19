maybe_parent(v::SubArray) = parent(v)
maybe_parent(v) = v

function indices(lengths)
    inds = UnitRange{Int64}[]
    firstidx=1
    for (i,len) in enumerate(lengths)
        lastidx = firstidx + len - 1
        push!(inds, firstidx:lastidx)
        firstidx = lastidx + 1
    end
    return Tuple(inds)
end

recursive_length(x) = length(x)
recursive_length(a::AbstractVector{N}) where N<:Number = length(a)
recursive_length(a::AbstractVector) = recursive_length.(a) |> sum
recursive_length(nt::NamedTuple) = values(nt) .|> recursive_length |> sum
