function run_imb_p2p(benchmark::MPIBenchmark, func::Function, conf::Configuration;
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
            error("IMB point-to-point benchmarks require exactly 2 MPI ranks")
        else
            exit()
        end
    end

    # Warmup
    func(conf.T, 1, 10, comm)

    if iszero(rank)
        print_header(io) = println(io, "size (bytes),iterations,time (seconds),throughput (MB/s),alloc (B)")
        print_timings(io, bytes, iters, latency, throughput,alloc) = println(io, bytes, ",", iters, ",", latency, ",", throughput, ",", alloc)

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
        time, alloc = func(conf.T, size, iters, comm)

        if !iszero(rank)
            # If we aren't on rank 0, send to it our time
            MPI.Send([time,alloc], comm; dest=0)
        else
            # Time on rank 0
            time_0, alloc_0 = time, alloc
            # Time on rank 1
            time_1, alloc_1 = MPI.Recv!([time, alloc], comm; source=1)
            # Maximum of the times measured across all ranks
            max_time = max(time_0, time_1)
            max_alloc = max(alloc_0, alloc_1)

            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)
            # Latency
            latency = max_time
            if divide_latency_by_two
                # I don't follow all the steps in IMB PingPong benchmark, but here they
                # divide latency by two (number of ranks)
                latency /= 2
            end
            # Throughput
            throughput = bytes / latency / 1e6

            # Print out our results
            print_timings(conf.stdout, bytes, iters, latency, throughput, max_alloc)
            if !isnothing(conf.filename)
                print_timings(file, bytes, iters, latency, throughput, max_alloc)
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

include("imb_pingpong.jl")
include("imb_pingping.jl")
