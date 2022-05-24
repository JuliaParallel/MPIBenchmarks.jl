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
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Alltoall!(UBuffer(buffer, Cint(bufsize), Cint(nranks), MPI.Datatype(T)), comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBAlltoall) = run_imb_collective(bench, imb_alltoall, bench.conf)
