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
    cache_size =  off_cache # Required in Bytes
    num_buffers = max(1, 2 * cache_size ÷ max(1, (sizeof(T) * bufsize)))    
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
