export IMBAlltoall

struct IMBAlltoall <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBAlltoall(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_imb_alltoall.csv",
                     kwargs...,
                     )
    return IMBAlltoall(
        Configuration(T; filename, kwargs...),
        "IMB Alltoall",
    )
end

function imb_alltoall(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    buffer = zeros(T, bufsize * nranks)
    root = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        MPI.Alltoall!(UBuffer(buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)), comm)
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(bench::IMBAlltoall) = run_imb_collective(bench, imb_alltoall, bench.conf)
