export OSUScatter

struct OSUScatter <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUScatter(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_scatter.csv",
                   kwargs...,
                   )
    return OSUScatter(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Scatter",
    )
end

function osu_scatter(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize * nranks)
    recv_buffer = zeros(T, bufsize)
    root = 0
    timer = 0.0

    MPI.Barrier(comm)
    for _ in 1:iters
        tic = MPI.Wtime()
        if rank == root   
            MPI.Scatter!(UBuffer(send_buffer, Cint(bufsize), nranks,MPI.Datatype(T)), recv_buffer, comm; root)
        else
            MPI.Scatter!(nothing, recv_buffer, comm; root)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    MPI.Barrier(comm)
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUScatter) = run_osu_collective(bench, osu_scatter, bench.conf)
