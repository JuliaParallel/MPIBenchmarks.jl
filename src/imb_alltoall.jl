export IMBAlltoall

struct IMBAlltoall <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBAlltoall(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_imb_alltoall.csv",
                     kwargs...,
                     )
    return IMBAlltoall(
        Configuration(T; filename, kwargs...),
        "IMB Alltoall",
    )
end

function imb_alltoall(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, off_cache::Int64 )
    # If the "off_cache" is equal to zero then there will be no cache avoidance, and only single array of send_buffer & recv_buffer will be created.
    cache_size =  off_cache # Required in Bytes
    
    # To avoid integer division error when bufsize is equal to zero
    if bufsize == 0
        num_buffers = max(1, 2 * cache_size)
    else
        num_buffers = max(1, 2 * cache_size ÷ (sizeof(T) * bufsize))
    end
    
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    buffer = [zeros(T, bufsize * nranks) for _ in 1:num_buffers]
    timer = 0.0

    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Alltoall!(UBuffer(@inbounds(buffer[mod1(i, num_buffers)]), Cint(bufsize), Cint(nranks), MPI.Datatype(T)), comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBAlltoall) = run_imb_collective(bench, imb_alltoall, bench.conf)
