export OSUAlltoallv

struct OSUAlltoallv <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUAlltoallv(T::Type=Float32;
                     filename::Union{String,Nothing}="julia_osu_alltoallv.csv",
                     kwargs...,
                     )
    return OSUAlltoallv(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Alltoallv",
    )
end

function osu_alltoallv(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize * nranks)
    recv_buffer = zeros(T, bufsize * nranks)
    counts = fill(bufsize, nranks)
    timer = 0.0
    MPI.Barrier(comm)

    for _ in 1:iters
        tic = MPI.Wtime()
        MPI.Alltoallv!(
            VBuffer(send_buffer, counts),
            VBuffer(recv_buffer, counts),
            comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUAlltoallv) = run_osu_collective(bench, osu_alltoallv, bench.conf)
