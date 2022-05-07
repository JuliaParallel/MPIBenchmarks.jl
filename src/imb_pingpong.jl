export IMBPingPong

struct IMBPingPong <: MPIBenchmark
    name::String
    default_filename::String
end
IMBPingPong() = IMBPingPong("IMB PingPong", "julia_imb_pingpong.csv")

function imb_pingpong(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    buffer = zeros(T, bufsize)
    tag = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        if iszero(rank)
            MPI.Send(buffer, comm; dest=1, tag)
            MPI.Recv!(buffer, comm; source=1, tag)
        elseif isone(rank)
            # Note: this branch must run on rank 1 only: if the benchmark is run with more
            # than 2 MPI ranks, the other ranks would wait indefinitely for a message from
            # rank 0.
            MPI.Recv!(buffer, comm; source=0, tag)
            MPI.Send(buffer, comm; dest=0, tag)
        end
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(bench::IMBPingPong, conf::Configuration) =
    run_imb_p2p(bench, imb_pingpong, conf)
