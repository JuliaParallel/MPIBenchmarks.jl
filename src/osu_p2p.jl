function run_osu_p2p(benchmark::MPIBenchmark, func::Function, conf::Configuration;
                     divide_latency_by_two::Bool=false)
    MPI.Init()

    comm = MPI.COMM_WORLD
    # Current rank
    rank = MPI.Comm_rank(comm)
    # Number of ranks
    nranks = MPI.Comm_size(comm)
    if nranks != 2
        # Throw error only on rank 0, to avoid messy error messages
        if iszero(rank)
            error("OSU point-to-point benchmarks require exactly 2 MPI ranks")
        else
            exit()
        end
    end

    # Warmup
    func(conf.T, 1, 10, comm)

    if iszero(rank)
        print_header(io) = println(io, "size (bytes),iterations,latency (seconds)")
        print_timings(io, bytes, iters, latency) = println(io, bytes, ",", iters, ",", latency)

        println(conf.stdout, "----------------------------------------")
        println(conf.stdout, "Running benchmark ", benchmark.name, " with type ", conf.T, " on ", nranks, " MPI ranks")
        println(conf.stdout)
        print_header(conf.stdout)
        if !isnothing(conf.filename)
            file = open(conf.filename, "w")
            print_header(file)
        end
    end

    for s in conf.lengths
        size = 1 << s
        iters = conf.iters(conf.T, s)
        # Measure time on current rank
        time = func(conf.T, size, iters, comm)

        if iszero(rank)
            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)
            latency = time / 2

            # Print out our results
            print_timings(conf.stdout, bytes, iters, latency)
            if !isnothing(conf.filename)
                print_timings(file, bytes, iters, latency)
            end
        end
    end

    if iszero(rank)
        println(conf.stdout, "----------------------------------------")
        if !isnothing(conf.filename)
            close(file)
        end
    end

    return nothing
end

include("osu_latency.jl")
