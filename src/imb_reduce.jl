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

function imb_reduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, off_cache::Int64)
    cache_size =  off_cache # Required in Bytes
    num_buffers = max(1, 2 * cache_size ÷ max(1, (sizeof(T) * bufsize)))
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
