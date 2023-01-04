export OSUBw

struct OSUBw <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUBw(T::Type=Float32;
                   filename::Union{String,Nothing}="julia_osu_bw.csv",
                   kwargs...,
                   )
    return OSUBw(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
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
            MPI.send(send_buffer, comm; dest=root, tag=101)
        end
    end
    return timer / iters
end

benchmark(bench::OSUBw) = run_osu_p2p(bench, osu_bw, bench.conf; cal_bandwidth=true)
