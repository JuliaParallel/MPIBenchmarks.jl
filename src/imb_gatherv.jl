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

function imb_gatherv(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = zeros(T, bufsize)
    recv_buffer = zeros(T, bufsize * nranks)
    counts = [bufsize for _ in 1:nranks]
    root = 0
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        if rank == root
            MPI.Gatherv!(MPI.IN_PLACE, VBuffer(recv_buffer, counts), comm; root)
        else
            MPI.Gatherv!(send_buffer, nothing, comm; root)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBGatherv) = run_imb_collective(bench, imb_gatherv, bench.conf)
