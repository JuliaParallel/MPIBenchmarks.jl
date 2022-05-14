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
    tag = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        if iszero(rank)
            request = MPI.Isend(send_buffer, comm; dest=1, tag)
            MPI.Recv!(recv_buffer, comm; source=1, tag)
            MPI.Wait(request)
        elseif isone(rank)
            request = MPI.Isend(send_buffer, comm; dest=0, tag)
            MPI.Recv!(recv_buffer, comm; source=0, tag)
            MPI.Wait(request)
        end
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

benchmark(bench::IMBPingPing) = run_imb_p2p(bench, imb_pingping, bench.conf)
