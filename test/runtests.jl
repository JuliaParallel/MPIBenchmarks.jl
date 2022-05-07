using Test
using MPIBenchmarks: Configuration
using MPI: mpiexec

@testset "Configuration" begin
    conf_uint8 = Configuration(UInt8)
    @test conf_uint8.T === UInt8
    @test conf_uint8.lengths == -1:22
    @test all(==(1000), conf_uint8.iters.(-1:15))
    @test conf_uint8.iters.(16:22) == [640, 320, 160, 80, 40, 20, 10]
    @test conf_uint8.stdout === Base.stdout
    @test isnothing(conf_uint8.filename)

    conf_float32 = Configuration(Float32; max_size=1<<16)
    @test conf_float32.T === Float32
    @test conf_float32.lengths == -1:14
    @test all(==(1000), conf_float32.iters.(-1:13))
    @test conf_float32.iters.(14:16) == [640, 320, 160]
    @test conf_float32.stdout === Base.stdout
    @test isnothing(conf_float32.filename)

    conf_float64 = Configuration(Float64)
    @test conf_float64.T === Float64
    @test conf_float64.lengths == -1:19
    @test all(==(1000), conf_float64.iters.(-1:12))
    @test conf_float64.iters.(13:19) == [640, 320, 160, 80, 40, 20, 10]
    @test conf_float64.stdout === Base.stdout
    @test isnothing(conf_float64.filename)

    @test_throws ArgumentError Configuration(Configuration)
    @test_throws ArgumentError Configuration(UInt8; max_size=10)
    @test_throws ArgumentError Configuration(UInt64; max_size=2)
end

@testset "Run benchmarks" begin
    julia = `$(Base.julia_cmd()) --startup-file=no`
    @testset "IMB - Collective" begin
        script = """
            using MPIBenchmarks
            const verbose = false
            mktemp() do filename, io
                run(IMBAllreduce(; verbose, filename))
                run(IMBAlltoall(; verbose, filename, max_size=1<<16))
                run(IMBGatherv(; verbose, filename))
                run(IMBReduce(; verbose, filename))
            end
            """
        @test success(mpiexec(cmd->run(`$(cmd) -np 2 $(julia) --project -e $(script)`)))
    end

    @testset "IMB - Point-to-point" begin
        script = """
            using MPIBenchmarks
            const verbose = false
            mktemp() do filename, io
                run(IMBPingPong(; verbose, filename))
                run(IMBPingPing(; verbose, filename))
            end
            """
        @test success(mpiexec(cmd->run(`$(cmd) -np 2 $(julia) --project -e $(script)`)))
        # Point-to-point benchmarks require at least 2 processes
        script = """
            using MPIBenchmarks
            const verbose = false
            mktemp() do filename, io
                run(IMBPingPong(; verbose, filename))
            end
            """
        @test !success(mpiexec(cmd->ignorestatus(`$(cmd) -np 1 $(julia) --project -e $(script)`)))
    end
end
