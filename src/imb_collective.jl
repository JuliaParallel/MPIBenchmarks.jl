function run_imb_collective(bench_func::Function, conf::Configuration)
    MPI.Init()

    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)

    # Warmup
    bench_func(conf.T, 1, 10, comm)

    if !isnothing(conf.filename) && iszero(rank)
        file = open(conf.filename, "w")
        println(file, "size (bytes),min_time (seconds),max_time (seconds),avg_time (seconds)")
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
            # Number of ranks
            nranks = MPI.Comm_size(comm)
            # Vector of timings across all ranks
            times = zeros(nranks)
            # Set first element of the vector to the time on rank 0
            times[1] = time

            # Collect all the times from all other ranks
            for source in 1:(nranks - 1)
                times[source + 1] = MPI.Recv(typeof(time), comm; source)
            end

            # Minimum time measured across all ranks
            min_time = minimum(times)
            # Maximum time measured across all ranks
            max_time = maximum(times)
            # Average time measured across all ranks
            avg_time = sum(times) / length(times)

            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)

            # Print out our results
            if conf.verbose
                @show bytes, min_time, max_time, avg_time
            end
            if !isnothing(conf.filename)
                println(file, bytes, ",", min_time, ",", max_time, ",", avg_time)
            end
        end
    end

    if !isnothing(conf.filename) && iszero(rank)
        close(file)
    end    
end

include("imb_allreduce.jl")
include("imb_reduce.jl")
