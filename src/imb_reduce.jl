export IMBReduce

struct IMBReduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBReduce(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_imb_reduce.csv",
                   kwargs...,
                   )
    return IMBReduce(
        Configuration(T; filename, kwargs...),
        "IMB Reduce",
    )
end

function imb_reduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
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
    recv_buffer = [zeros(T, bufsize) for _ in 1:num_buffers]
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

benchmark(bench::IMBReduce) = run_imb_collective(bench, imb_reduce, bench.conf)
