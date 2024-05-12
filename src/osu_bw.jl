export OSUBw

struct OSUBw <: MPIBenchmark
    conf::Configuration
    name::String
end

function osu_bw_iterations(::Type{T}, s::Int) where {T}
    iter = 100
    if s < 0
        buf_size = 0
    else
        buf_size = 2^s * sizeof(T)
    end
    if buf_size > 8192
        iter = 20
    end
    return iter
end

function OSUBw(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_bw.csv",
                   kwargs...,
                   )
    return OSUBw(
        Configuration(T; filename, max_size=2 ^ 22, iterations=osu_bw_iterations, kwargs...),
        "OSU Bandwidth",
    )
end

function osu_bw(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, window_size::Int)
    send_buffer = zeros(T, bufsize)
    recv_buffer = ones(T, bufsize)
    timer = 0.0
    rank = MPI.Comm_rank(comm)
    root = 0
    send_list = Array{MPI.Request}(undef, window_size)
    recv_list = Array{MPI.Request}(undef, window_size)

    MPI.Barrier(comm)
    for _ in 1:iters
        if  rank == root
            tic = MPI.Wtime()
            for j in 1:window_size
                send_list[j] = MPI.Isend(send_buffer, comm; dest=1, tag=100)
            end
            MPI.Waitall(send_list)
            MPI.recv(comm; source=1, tag=101)
            toc = MPI.Wtime()
            timer += toc - tic
        else
            for k in 1:window_size
                recv_list[k] = MPI.Irecv!(recv_buffer, comm; source=0, tag=100)
            end
            MPI.Waitall(recv_list)
            done_msg = "1"
            MPI.send(done_msg, comm; dest=root, tag=101)
        end
    end
    return timer
end

benchmark(bench::OSUBw) = run_osu_p2p(bench, osu_bw, bench.conf; cal_bandwidth=true)
