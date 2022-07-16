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
    cache_size = 2 ^ 16 # Assume cache size of 64 KiB
    # To avoid hitting the cache, create buffers which are arrays of arrays of size
    # `bufsize` so that they exceed the cache size
    num_buffers = max(1, 2 * cache_size ÷ (sizeof(T) * bufsize))
    send_buffer = [zeros(T, bufsize) for _ in 1:num_buffers]
    recv_buffer = [ones(T, bufsize) for _ in 1:num_buffers]
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Reduce!(@inbounds(send_buffer[mod1(i, num_buffers)]), @inbounds(recv_buffer[mod1(i, num_buffers)]), +, comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUReduce) = run_osu_collective(bench, osu_reduce, bench.conf)
