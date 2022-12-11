export IMBGatherv

struct IMBGatherv <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBGatherv(T::Type=UInt8;
                    filename::Union{String,Nothing}="julia_imb_gatherv.csv",
                    kwargs...,
                    )
    return IMBGatherv(
        Configuration(T; filename, kwargs...),
        "IMB Gatherv",
    )
end

function imb_gatherv(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, off_cache::Int64)
    cache_size =  off_cache # Required in Bytes
    num_buffers = max(1, 2 * cache_size ÷ max(1, (sizeof(T) * bufsize)))
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = [zeros(T, bufsize) for _ in 1:num_buffers]
    recv_buffer = [zeros(T, bufsize * nranks) for _ in 1:num_buffers]
    counts = [bufsize for _ in 1:nranks]
    root = 0
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        if rank == root
            MPI.Gatherv!(MPI.IN_PLACE, VBuffer(@inbounds(recv_buffer[mod1(i, num_buffers)]), counts), comm; root)
        else
            MPI.Gatherv!(@inbounds(send_buffer[mod1(i, num_buffers)]), nothing, comm; root)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBGatherv) = run_imb_collective(bench, imb_gatherv, bench.conf)
