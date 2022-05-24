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
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        if iszero(rank)
            request = MPI.Isend(send_buffer, comm; dest=1, tag)
            MPI.Recv!(recv_buffer, comm; source=1, tag)
            MPI.Wait(request)
        elseif isone(rank)
            request = MPI.Isend(send_buffer, comm; dest=0, tag)
            MPI.Recv!(recv_buffer, comm; source=0, tag)
            MPI.Wait(request)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBPingPing) = run_imb_p2p(bench, imb_pingping, bench.conf)
