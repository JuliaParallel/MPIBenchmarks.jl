using Test
using MPIBenchmarks: Configuration, benchmark
using MPI: mpiexec

@testset "Configuration" begin
    conf_uint8 = Configuration(UInt8)
    @test conf_uint8.T === UInt8
    @test conf_uint8.lengths == -1:22
    @test all(==(1 << 20), conf_uint8.iters.(conf_uint8.T, -1:10))
    @test conf_uint8.iters.(conf_uint8.T, 11:22) == 1 .<< (19:-1:8)
    @test conf_uint8.stdout === Base.stdout
    @test isnothing(conf_uint8.filename)

    iterations(T::Type, s::Int) = 1 << (25 - trailing_zeros(sizeof(T)) - s)
    conf_float32 = Configuration(Float32; max_size=1<<16, iterations)
    @test conf_float32.T === Float32
    @test conf_float32.lengths == -1:14
    @test conf_float32.iters.(conf_float32.T, -1:14) == 1 .<< (24:-1:9)
    @test conf_float32.stdout === Base.stdout
    @test isnothing(conf_float32.filename)

    conf_float64 = Configuration(Float64)
    @test conf_float64.T === Float64
    @test conf_float64.lengths == -1:19
    @test all(==(1 << 17), conf_float64.iters.(conf_float64.T, -1:7))
    @test conf_float64.iters.(conf_float64.T, 8:19) == 1 .<< (16:-1:5)
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

                benchmark(OSUBroadcast(; verbose, filename))
                benchmark(OSUGather(; verbose, filename))
                benchmark(OSUScatter(; verbose, filename))
                benchmark(OSUAllgather(; verbose, filename))

                benchmark(OSUScatterv(; verbose, filename))
                benchmark(OSUGatherv(; verbose, filename))
                benchmark(OSUAllgatherv(; verbose, filename))
                benchmark(OSUAlltoallv(; verbose, filename))

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
