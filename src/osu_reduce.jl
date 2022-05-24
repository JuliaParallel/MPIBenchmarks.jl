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
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Reduce",
    )
end

function osu_reduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    send_buffer = zeros(T, bufsize)
    recv_buffer = ones(T, bufsize)
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Reduce!(send_buffer, recv_buffer, +, comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUReduce) = run_osu_collective(bench, osu_reduce, bench.conf)
