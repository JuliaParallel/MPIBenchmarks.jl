export OSUGather

struct OSUGather <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUGather(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_gather.csv",
                   kwargs...,
                   )
    return OSUGather(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Gather",
    )
end

function osu_gather(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize)
    recv_buffer = zeros(T, bufsize * nranks)
    root = 0
    timer = 0.0

    MPI.Barrier(comm)
    for _ in 1:iters
        tic = MPI.Wtime()
        if rank == root   
            MPI.Gather!(MPI.IN_PLACE, UBuffer(recv_buffer, Cint(bufsize) , nranks , MPI.Datatype(T)), comm; root)
        else
            MPI.Gather!(send_buffer, nothing, comm; root)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    MPI.Barrier(comm)
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUGather) = run_osu_collective(bench, osu_gather, bench.conf)
