export OSUAllgather

struct OSUAllgather <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUAllgather(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_allgather.csv",
                   kwargs...,
                   )
    return OSUAllgather(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU All Gather",
    )
end

function osu_allgather(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize)
    recv_buffer = zeros(T, bufsize * nranks)
    timer = 0.0

    MPI.Barrier(comm)
    for _ in 1:iters
        tic = MPI.Wtime()
        MPI.Allgather!(send_buffer, UBuffer(recv_buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)), comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    MPI.Barrier(comm)
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUAllgather) = run_osu_collective(bench, osu_allgather, bench.conf)
