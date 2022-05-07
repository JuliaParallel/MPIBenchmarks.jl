using Test
using MPIBenchmarks: Configuration
using MPI: mpiexec

@testset "Configuration" begin
    conf_uint8 = Configuration(UInt8)
    @test conf_uint8.T === UInt8
    @test conf_uint8.lengths == -1:22
    @test all(==(1000), conf_uint8.iters.(-1:15))
    @test conf_uint8.iters.(16:22) == [640, 320, 160, 80, 40, 20, 10]
    @test conf_uint8.verbose === true
    @test isnothing(conf_uint8.filename)

    conf_float32 = Configuration(Float32)
    @test conf_float32.T === Float32
    @test conf_float32.lengths == -1:20
    @test all(==(1000), conf_float32.iters.(-1:13))
    @test conf_float32.iters.(14:20) == [640, 320, 160, 80, 40, 20, 10]
    @test conf_float32.verbose === true
    @test isnothing(conf_float32.filename)

    conf_float64 = Configuration(Float64)
    @test conf_float64.T === Float64
    @test conf_float64.lengths == -1:19
    @test all(==(1000), conf_float64.iters.(-1:12))
    @test conf_float64.iters.(13:19) == [640, 320, 160, 80, 40, 20, 10]
    @test conf_float64.verbose === true
    @test isnothing(conf_float64.filename)
end

@testset "Run benchmarks" begin
    julia = `julia --startup-file=no`
    @testset "IMB - Collective" begin
        script = """
            using MPIBenchmarks
            conf = MPIBenchmarks.Configuration(UInt8; verbose=false, filename=nothing)
            run(IMBAllreduce, conf)
            run(IMBReduce, conf)
            """
        @test success(mpiexec(cmd->run(`$(cmd) -np 2 $(julia) --project -e $(script)`)))
    end

    @testset "IMB - Point-to-point" begin
        script = """
            using MPIBenchmarks
            conf = MPIBenchmarks.Configuration(UInt8; verbose=false, filename=nothing)
            run(IMBPingPong, conf)
            """
        @test success(mpiexec(cmd->run(`$(cmd) -np 2 $(julia) --project -e $(script)`)))
    end
end
