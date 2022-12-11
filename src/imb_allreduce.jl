export IMBAllreduce

struct IMBAllreduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBAllreduce(T::Type=Float32;
                      filename::Union{String,Nothing}="julia_imb_allreduce.csv",
                      kwargs...,
                      )
    return IMBAllreduce(
        Configuration(T; filename, kwargs...),
        "IMB Allreduce",
    )
end

function imb_allreduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, off_cache::Int64)
    # If the "off_cache" is equal to zero then there will be no cache avoidance, and only single array of send_buffer & recv_buffer will be created.
    cache_size =  off_cache # Required in Bytes
    
    # To avoid integer division error when bufsize is equal to zero
    num_buffers = max(1, 2 * cache_size ÷ max(1, (sizeof(T) * bufsize)))
    
    send_buffer = [zeros(T, bufsize) for _ in 1:num_buffers]
    recv_buffer = [zeros(T, bufsize) for _ in 1:num_buffers]

    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Allreduce!(@inbounds(send_buffer[mod1(i, num_buffers)]), @inbounds(recv_buffer[mod1(i, num_buffers)]), +, comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBAllreduce) = run_imb_collective(bench, imb_allreduce, bench.conf)
