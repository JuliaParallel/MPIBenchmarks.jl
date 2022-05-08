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
        Configuration(T; filename, class=:osu_collective, max_size=2 ^ 20, kwargs...),
        "OSU Alltoall",
    )
end

function osu_alltoall(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    send_buffer = ones(T, bufsize * nranks)
    recv_buffer = zeros(T, bufsize * nranks)
    root = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        MPI.Alltoall!(
            UBuffer(send_buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)),
            UBuffer(recv_buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)),
            comm)
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(bench::OSUAlltoall) = run_osu_collective(bench, osu_alltoall, bench.conf)
