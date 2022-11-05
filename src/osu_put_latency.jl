export OSUPutLatency

struct OSUPutLatency <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUPutLatency(T::Type=Float32;
                     filename::Union{String,Nothing}="julia_osu_put_latency.csv",
                     kwargs...,
                     )
    return OSUPutLatency(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Put Latency",
    )
end

function osu_put_latency(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, synchronization_option::String)
    win = MPI.Win_create(ones(T, bufsize), comm)
    if synchronization_option == "lock"
       return run_put_with_lock(T, bufsize, iters, comm, win)
    elseif synchronization_option == "fence"
       return run_put_with_fence(T, bufsize, iters, comm, win)
    end
end

function run_put_with_lock(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, win::MPI.Win)
    rank = MPI.Comm_rank(comm)
    buffer = ones(T, bufsize)
    root = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()

    if rank == root
        for _ in 1:iters
            MPI.Win_lock(MPI.LOCK_SHARED, 1, 0, win)
            MPI.Put!(buffer, 1, 0, win)   #Parameter: data, rank, disp, win
            MPI.Win_unlock(1, win)
        end
    end
    MPI.Barrier(comm)
    toc = MPI.Wtime()
    timer = toc - tic
    MPI.free(win)
    return timer
end

function run_put_with_fence(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, win::MPI.Win)
    rank = MPI.Comm_rank(comm)
    buffer = ones(T, bufsize)
    root = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    if rank == root
        for _ in 1:iters
            MPI.Win_fence(0, win)
            MPI.Put!(buffer, 1, 0, win)   #Parameter: data, rank, disp, win
            MPI.Win_fence(0, win)
        end
    else
        for _ in 1:iters
            MPI.Win_fence(0, win)
            MPI.Put!(buffer, 0, 0, win)   #Parameter: data, rank, disp, win
            MPI.Win_fence(0, win)
        end
    end
    MPI.Barrier(comm)
    toc = MPI.Wtime()
    timer = toc - tic
    MPI.free(win)
    return timer
end

benchmark(bench::OSUPutLatency) = run_osu_one_sided(bench, osu_put_latency, bench.conf)
