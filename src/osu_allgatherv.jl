export OSUAllgatherv

struct OSUAllgatherv <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUAllgatherv(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_allgatherv.csv",
                   kwargs...,
                   )
    return OSUAllgatherv(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU ALLgatherv",
    )
end

function osu_allgatherv(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize)
    recv_buffer = zeros(T, bufsize * nranks)
    counts = fill(bufsize, nranks)
    root = 0
    timer = 0.0
    MPI.Barrier(comm)
    for _ in 1:iters
        tic = MPI.Wtime()
        if rank == root
            MPI.Gatherv!(MPI.IN_PLACE, VBuffer(recv_buffer, counts), comm; root)
        else
            MPI.Gatherv!(send_buffer, nothing, comm; root)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    MPI.Barrier(comm)
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUAllgatherv) = run_osu_collective(bench, osu_allgatherv, bench.conf)
