function run_imb_p2p(benchmark::MPIBenchmark, func::Function, conf::Configuration)
    MPI.Init()

    comm = MPI.COMM_WORLD
    # Number of ranks: since these are point-to-point benchmarks, let's pretend we have
    # always 2 ranks.  This is important because `nranks` will be used below to estimate
    # latency and throughput.  But let's check that we actually have at least 2 ranks.
    nranks = 2
    if MPI.Comm_size(comm) < 2
        error("Point-to-point benchmarks require at least 2 MPI ranks")
    end
    # Current rank
    rank = MPI.Comm_rank(comm)

    # Warmup
    func(conf.T, 1, 10, comm)

    if iszero(rank)
        print_header(io) = println(io, "size (bytes),time (seconds),throughput (MB/s)")
        print_timings(io, bytes, latency, throughput) = println(io, bytes, ",", latency, ",", throughput)

        println(conf.stdout, "----------------------------------------")
        println(conf.stdout, "Running benchmark ", benchmark.name, " on ", nranks, " MPI ranks")
        println(conf.stdout)
        print_header(conf.stdout)
        if !isnothing(conf.filename)
            file = open(conf.filename, "w")
            print_header(file)
        end
    end

    for s in conf.lengths
        size = 1 << s
        iters = conf.iters(s)
        # Measure time on current rank
        time = func(conf.T, size, iters, comm)

        if !iszero(rank)
            # If we aren't on rank 0, send to it our time
            MPI.Send(time, comm; dest=0)
        else
            # Time on rank 0
            time_0 = time
            # Time on rank 1
            time_1 = MPI.Recv(typeof(time), comm; source=1)
            # Maximum of the times measured across all ranks
            max_time = max(time_0, time_1)
            # Aggregate time across all ranks
            aggregate_time = time_0 + time_1

            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)
            # Latency
            latency = aggregate_time / (2 * nranks)
            # Throughput
            throughput = (nranks * bytes) / max_time / 1e6

            # Print out our results
            print_timings(conf.stdout, bytes, latency, throughput)
            if !isnothing(conf.filename)
                print_timings(file, bytes, latency, throughput)
            end
        end
    end

    if iszero(rank)
        println(conf.stdout, "----------------------------------------")
        if !isnothing(conf.filename)
            close(file)
        end
    end
end

include("imb_pingpong.jl")
