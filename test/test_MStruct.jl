nt = (a=5, b=[(a=20, b=2), (a=33, b=0), (a=44, b=3.3)], c=(a=2, b=[1, 2.0]))
ms = MStruct(a=5, b=[(a=20, b=2), (a=33, b=0), (a=44, b=3.3)], c=(a=2, b=[1, 2.0]))

@testset "Construction" begin
    @test MStruct(nt) == ms
    @test MStruct{Float64}(nt) == ms
    @test eltype(MStruct{ForwardDiff.Dual}(nt)) == ForwardDiff.Dual
end

@testset "Attributes" begin
    @test length(ms) == 10
    @test size(ms) == (10,)
    @test propertynames(ms) == (:a, :b, :c)

    # Make sure MStruct internal fields aren't accessed when keys have same name
    @testset "With reserved keywords" begin
        with_reserved = MStruct{Int64}(a=1, data=[2,3])
        with_reserved.data[2] = 4
        @test with_reserved.data == [2,4]
        @test propertynames(with_reserved) == (:a, :data)
    end
end

@testset "Similarity" begin
    @test typeof(similar(ms)) == typeof(ms)
    @test typeof(similar(ms, Float32)) == typeof(MStruct{Float32}(nt))
    @test eltype(similar(ms, Float32)) == Float32
    @test eltype(similar(ms, ForwardDiff.Dual)) == ForwardDiff.Dual
end

@testset "Conversion" begin
    nt_homogeneous = (a=5., b=[(a=20., b=2.), (a=33., b=0.), (a=44., b=3.3)], c=(a=2., b=[1., 2.]))
    @test NamedTuple(ms) == nt_homogeneous
end

@testset "Set/Get" begin
    ms2 = deepcopy(ms)

    ms2.a = 20
    @test ms2.a == 20

    ms2.c.a = 50
    @test ms2.c.a == 50

    ms2.b[1].b = 30
    @test ms2.b[1].b == 30

    @test ms[:b][1]["a"] == 20
    @test collect(ms) == Float64[5, 20, 2, 33, 0, 44, 3.3, 2, 1, 2]
    @test ms[:] == collect(ms)
    @test ms[2:5] == Float64[20, 2, 33, 0]
    @test ms[end] == 2
end
