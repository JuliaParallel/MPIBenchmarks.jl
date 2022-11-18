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
    # for Noctua 1, L3 cache is 27.5 MiB
    # l3: 27.5*1024*1024 = 28835840
    cache_size =  28835840 
    
    # To avoid integer division error when bufsize is equal to zero
    if bufsize == 0
        num_buffers = max(1, 2 * cache_size)
    else
        num_buffers = max(1, 2 * cache_size ÷ (sizeof(T) * bufsize))
    end
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
