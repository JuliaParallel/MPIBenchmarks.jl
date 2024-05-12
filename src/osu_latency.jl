export OSULatency

struct OSULatency{T} <: MPIBenchmark
    conf::Configuration{T}
    name::String
end

function osu_latency_iterations(::Type{T}, s::Int) where {T}
    iter = 10000
    if s < 0
        buf_size = 0
    else
        buf_size = 2^s * sizeof(T)
    end
    if buf_size > 8192
        iter = 1000
    end
    return iter
end

function OSULatency(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_osu_latency.csv",
                     kwargs...,
                     )
    return OSULatency{T}(
        Configuration(T; filename, max_size=2 ^ 22, iterations=osu_latency_iterations, kwargs...),
        "OSU Latency",
    )
end

function osu_latency(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, window_size::Int)
    rank = MPI.Comm_rank(comm)
    send_buffer = rand(T, bufsize)
    recv_buffer = rand(T, bufsize)
    tag = 0
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        if iszero(rank)
            MPI.Send(send_buffer, comm; dest=1, tag)
            MPI.Recv!(recv_buffer, comm; source=1, tag)
        elseif isone(rank)
            MPI.Recv!(recv_buffer, comm; source=0, tag)
            MPI.Send(send_buffer, comm; dest=0, tag)
        end
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSULatency) = run_osu_p2p(bench, osu_latency, bench.conf)
