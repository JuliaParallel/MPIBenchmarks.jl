function run_imb_collective(benchmark::MPIBenchmark, func::Function, conf::Configuration)
    MPI.Init()

    comm = MPI.COMM_WORLD
    # Current rank
    rank = MPI.Comm_rank(comm)
    # Number of ranks
    nranks = MPI.Comm_size(comm)

    # Warmup
    func(conf.T, 1, 10, comm)

    if iszero(rank)
        print_header(io) = println(io, "size (bytes),iterations,min_time (seconds),max_time (seconds),avg_time (seconds)")
        print_timings(io, bytes, iters, min_time, max_time, avg_time) = println(io, bytes, ",", iters, ",", min_time, ",", max_time, ",", avg_time)

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

        if !iszero(rank)
            # If we aren't on rank 0, send to it our time
            MPI.Send(time, comm; dest=0)
        else
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
            print_timings(conf.stdout, bytes, iters, min_time, max_time, avg_time)
            if !isnothing(conf.filename)
                print_timings(file, bytes, iters, min_time, max_time, avg_time)
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

include("imb_allreduce.jl")
include("imb_alltoall.jl")
include("imb_gatherv.jl")
include("imb_reduce.jl")
