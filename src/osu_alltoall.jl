export OSUAlltoall

struct OSUAlltoall <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUAlltoall(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_osu_alltoall.csv",
                     kwargs...,
                     )
    return OSUAlltoall(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Alltoall",
    )
end

function osu_alltoall(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize * nranks)
    recv_buffer = zeros(T, bufsize * nranks)
    root = 0
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Alltoall!(
            UBuffer(send_buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)),
            UBuffer(recv_buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)),
            comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUAlltoall) = run_osu_collective(bench, osu_alltoall, bench.conf)
