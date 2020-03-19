using ModelingStructs: maybe_parent, indices, recursive_length

@testset "Utilities" begin
    @testset "maybe_parent" begin
        a = [1,2,3,4]
        b = view(a, 1:3)
        c = view(b, 2)
        @test maybe_parent(b) === a
        @test maybe_parent(c) === a
    end

    @testset "indices" begin
        lengths = [1,3,6,1]
        inds = indices(lengths)
        @test inds == (1:1, 2:4, 5:10, 11:11)
        @test last(last(inds)) == sum(lengths)
    end

    @testset "recursive_length" begin
        single = 1
        vect = [1, 2, 3, 4]
        nest_vect = [1, 2, [3, 4]]
        nt = (a=1, b=2)
        nest_nt = (a=single, b=nt, c=[nt, nt], d=(a=vect, b=nest_vect), e=(a=nt, b=nest_vect))
        @test recursive_length(single) == 1
        @test recursive_length(vect) == 4
        @test recursive_length(nest_vect) == 4
        @test recursive_length(nt) == 2
        @test recursive_length(nest_nt) == 21
    end
end
