export OSUReduce

struct OSUReduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUReduce(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_reduce.csv",
                   kwargs...,
                   )
    return OSUReduce(
        Configuration(T; filename, class=:osu_collective, max_size=2 ^ 20, kwargs...),
        "OSU Reduce",
    )
end

function osu_reduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    send_buffer = zeros(T, bufsize)
    recv_buffer = ones(T, bufsize)
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        MPI.Reduce!(send_buffer, recv_buffer, +, comm)
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

benchmark(bench::OSUReduce) = run_osu_collective(bench, osu_reduce, bench.conf)
