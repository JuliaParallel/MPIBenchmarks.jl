export OSUBroadcast

struct OSUBroadcast <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUBroadcast(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_broadcast.csv",
                   kwargs...,
                   )
    return OSUBroadcast(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Broadcast",
    )
end

function osu_broadcast(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    send_buffer = ones(T, bufsize)
    timer = 0.0
    MPI.Barrier(comm)
    for _ in 1:iters
        tic = MPI.Wtime()
        MPI.Bcast!(send_buffer, 0 , comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    MPI.Barrier(comm)
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUBroadcast) = run_osu_collective(bench, osu_broadcast, bench.conf)
