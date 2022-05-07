function run_imb_p2p(bench_func::Function, conf::Configuration)
    MPI.Init()

    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)

    # Warmup
    bench_func(conf.T, 1, 10, comm)

    if !isnothing(conf.filename) && iszero(rank)
        file = open(conf.filename, "w")
        println(file, "size (bytes),time (seconds),throughput (MB/s)")
    end

    for s in conf.lengths
        size = 1 << s
        iters = conf.iters(s)
        # Measure time on current rank
        time = bench_func(conf.T, size, iters, comm)

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

            # Number of ranks
            nranks = MPI.Comm_size(comm)
            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)
            # Latency
            latency = aggregate_time / (2 * nranks)
            # Throughput
            throughput = (nranks * bytes) / max_time / 1e6

            # Print out our results
            if conf.verbose
                @show bytes, latency, throughput
            end
            if !isnothing(conf.filename)
                println(file, bytes, ",", latency, ",", throughput)
            end
        end
    end

    if !isnothing(conf.filename) && iszero(rank)
        close(file)
    end    
end

include("imb_pingpong.jl")
