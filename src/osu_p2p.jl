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
        print_header(io) = cal_bandwidth == true ? println(io, "size (bytes),iterations,bandwidth (MB/s)") :  println(io, "size (bytes),iterations,latency (seconds)")
        print_result(io, bytes, iters, result) = println(io, bytes, ",", iters, ",", result)
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
        iters = conf.iters isa Function ?  conf.iters(conf.T, s) : conf.iters
        # Measure time on current rank
        time = func(conf.T, size, iters, comm, conf.window_size)

        if iszero(rank)
            # Number of bytes trasmitted
            bytes = size * sizeof(conf.T)
            latency = time / 2

            result = if cal_bandwidth
                tmp_total = bytes / 1e+6 * iters * conf.window_size
                tmp_total / time
            else
                latency
            end
            # Print out our results
                print_result(conf.stdout, bytes, iters, latency)
                if !isnothing(conf.filename)
                    print_result(file, bytes, iters, result)
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

