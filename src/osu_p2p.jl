using Printf

function run_osu_p2p(benchmark::MPIBenchmark, func::Function, conf::Configuration;
                     divide_latency_by_two::Bool=false, cal_bandwidth::Bool=false)
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
    func(conf.T, 1, 10, comm, conf.window_size)

    if iszero(rank)
        println(conf.stdout, "# ", benchmark.name, " with type ", conf.T, " on ", nranks, " MPI ranks")
        if cal_bandwidth
            println(conf.stdout, "size (bytes),iterations,bandwidth (MB/s)")
        else
            println(conf.stdout, "size (bytes),iterations,latency (us)")
        end
        if !isnothing(conf.filename)
            file = open(conf.filename, "w")
            if cal_bandwidth
                println(file, "size (bytes),iterations,bandwidth (MB/s)")
            else
                println(file, "size (bytes),iterations,latency (us)")
            end
        end
    end

    for s in conf.lengths
        size = 1 << s
        iters = conf.iters isa Function ?  conf.iters(conf.T, s) : conf.iters
        # Measure time on current rank
        time = func(conf.T, size, iters, comm, conf.window_size)

        if iszero(rank)
            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)
            latency = time / 2

            latency = if cal_bandwidth
                tmp_total = bytes * iters * conf.window_size / 2^20
                tmp_total / time
            else
                latency * 1e6
            end

            # Print out our results
            Printf.@printf(conf.stdout, "%d,%d,%.2f\n", bytes, iters, latency)
            if !isnothing(conf.filename)
                Printf.@printf(file, "%d,%d,%.2f\n", bytes, iters, latency)
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
include("osu_bw.jl")

