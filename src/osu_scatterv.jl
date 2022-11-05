export OSUScatterv

struct OSUScatterv <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUScatterv(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_scatterv.csv",
                   kwargs...,
                   )
    return OSUScatterv(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Scatterv",
    )
end

function osu_scatterv(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize * nranks)
    recv_buffer = zeros(T, bufsize)
    counts = fill(bufsize, nranks)
    root = 0
    timer = 0.0
    MPI.Barrier(comm)

    for _ in 1:iters
        tic = MPI.Wtime()
        if rank == root   
            MPI.Scatterv!(VBuffer(send_buffer, counts), recv_buffer, comm; root)
         else
             MPI.Scatterv!(nothing, recv_buffer, comm; root)
         end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    MPI.Barrier(comm)
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUScatterv) = run_osu_collective(bench, osu_scatterv, bench.conf)
