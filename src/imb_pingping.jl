export IMBPingPing

struct IMBPingPing{T} <: MPIBenchmark
    conf::Configuration{T}
    name::String
end

function IMBPingPing(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_imb_pingping.csv",
                     kwargs...,
                     )
    return IMBPingPing{T}(
        Configuration(T; filename, kwargs...),
        "IMB Pingping",
    )
end

function imb_pingping(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    send_buffer = zeros(T, bufsize)
    recv_buffer = zeros(T, bufsize)
    dest = source = iszero(rank) ? 1 : 0
    tag = 0
    timer = 0.0
    MPI.Barrier(comm)
    alloc = @allocated begin
        for i in 1:iters
            tic = MPI.Wtime()
            request = MPI.Isend(send_buffer, comm; dest, tag)
            MPI.Recv!(recv_buffer, comm; source, tag)
            MPI.Wait(request)
            toc = MPI.Wtime()
            timer += toc - tic
        end
    end
    avgtime = timer / iters
    avgalloc = alloc / iters
    return avgtime, avgalloc
end

benchmark(bench::IMBPingPing) = run_imb_p2p(bench, imb_pingping, bench.conf)
