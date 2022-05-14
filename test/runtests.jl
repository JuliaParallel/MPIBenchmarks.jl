using Test
using MPIBenchmarks: Configuration, benchmark
using MPI: mpiexec

@testset "Configuration" begin
    conf_uint8 = Configuration(UInt8)
    @test conf_uint8.T === UInt8
    @test conf_uint8.lengths == -1:22
    @test all(==(1000), conf_uint8.iters.(-1:15))
    @test conf_uint8.iters.(16:22) == [640, 320, 160, 80, 40, 20, 10]
    @test conf_uint8.stdout === Base.stdout
    @test isnothing(conf_uint8.filename)

    conf_uint8_osu_p2p = Configuration(UInt8; class=:osu_p2p)
    @test conf_uint8_osu_p2p.T === UInt8
    @test conf_uint8_osu_p2p.lengths == -1:22
    @test all(==(10000), conf_uint8_osu_p2p.iters.(-1:12))
    @test all(==(1000), conf_uint8_osu_p2p.iters.(13:22))
    @test conf_uint8_osu_p2p.stdout === Base.stdout
    @test isnothing(conf_uint8_osu_p2p.filename)

    conf_float32 = Configuration(Float32; max_size=1<<16)
    @test conf_float32.T === Float32
    @test conf_float32.lengths == -1:14
    @test all(==(1000), conf_float32.iters.(-1:13))
    @test conf_float32.iters.(14:16) == [640, 320, 160]
    @test conf_float32.stdout === Base.stdout
    @test isnothing(conf_float32.filename)

    conf_float32_osu_collective = Configuration(Float32; class=:osu_collective)
    @test conf_float32_osu_collective.T === Float32
    @test conf_float32_osu_collective.lengths == -1:20
    @test all(==(1000), conf_float32_osu_collective.iters.(-1:12))
    @test all(==(100), conf_float32_osu_collective.iters.(13:22))
    @test conf_float32_osu_collective.stdout === Base.stdout
    @test isnothing(conf_float32_osu_collective.filename)

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
                benchmark(IMBAllreduce(; verbose, filename))
                benchmark(IMBAlltoall(; verbose, filename, max_size=1<<16))
                benchmark(IMBGatherv(; verbose, filename))
                benchmark(IMBReduce(; verbose, filename))

                benchmark(OSUAllreduce(; verbose, filename))
                benchmark(OSUAlltoall(; verbose, filename))
                benchmark(OSUReduce(; verbose, filename))
            end
            """
        @test success(mpiexec(cmd->run(`$(cmd) -np 2 $(julia) --project -e $(script)`)))
    end

    @testset "IMB - Point-to-point" begin
        script = """
            using MPIBenchmarks
            const verbose = false
            mktemp() do filename, io
                benchmark(IMBPingPong(; verbose, filename))
                benchmark(IMBPingPing(; verbose, filename))
                benchmark(OSULatency(; verbose, filename))
            end
            """
        @test success(mpiexec(cmd->run(`$(cmd) -np 2 $(julia) --project -e $(script)`)))

        # IMB point-to-point benchmarks require at least 2 processes
        script = """
            using MPIBenchmarks
            const verbose = false
            mktemp() do filename, io
                benchmark(IMBPingPong(; verbose, filename))
            end
            """
        @test !success(mpiexec(cmd->ignorestatus(`$(cmd) -np 1 $(julia) --project -e $(script)`)))

        # OSU point-to-point benchmarks require exactly 2 processes
        script = """
            using MPIBenchmarks
            const verbose = false
            mktemp() do filename, io
                benchmark(OSULatency(; verbose, filename))
            end
            """
        @test !success(mpiexec(cmd->ignorestatus(`$(cmd) -np 3 $(julia) --project -e $(script)`)))
    end
end
