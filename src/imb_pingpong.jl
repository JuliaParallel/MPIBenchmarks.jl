export IMBPingPong

struct IMBPingPong{T} <: MPIBenchmark
    conf::Configuration{T}
    name::String
end

function IMBPingPong(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_imb_pingpong.csv",
                     kwargs...,
                     )
    return IMBPingPong{T}(
        Configuration(T; filename, kwargs...),
        "IMB Pingpong",
    )
end

function imb_pingpong(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    buffer = zeros(T, bufsize)
    tag = 0
    timer = 0.0
    alloc = 0
    MPI.Barrier(comm)
    alloc = @allocated begin
        for i in 1:iters
            tic = MPI.Wtime()
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
            toc = MPI.Wtime()
            timer += toc - tic
        end
    end
    avgtime = timer / iters
    avgalloc = alloc / iters
    return avgtime, avgalloc
end

benchmark(bench::IMBPingPong) = run_imb_p2p(bench, imb_pingpong, bench.conf; divide_latency_by_two=true)
