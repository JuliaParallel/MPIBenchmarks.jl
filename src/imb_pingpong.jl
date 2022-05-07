export IMBPingPong

struct IMBPingPong <: MPIBenchmark end

function imb_pingpong(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    buffer = zeros(T, bufsize)
    tag = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i = 1:iters
        if rank == 0
            MPI.Send(buffer, 1, tag, comm)
            MPI.Recv!(buffer, 1, tag, comm)
        elseif rank == 1
            MPI.Recv!(buffer, 0, tag, comm)
            MPI.Send(buffer, 0, tag, comm)
        end
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(::Type{IMBPingPong}, conf::Configuration) =
    run_imb_p2p(imb_pingpong, conf)

Base.run(bench::Type{IMBPingPong}; T::Type=UInt8, filename::Union{String,Nothing}="julia_imb_pingpong.csv") =
    Base.run(bench, Configuration(T; filename))
