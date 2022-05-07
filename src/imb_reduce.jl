export IMBReduce

struct IMBReduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBReduce(T::Type=UInt8;
                   filename::Union{String,Nothing}="julia_imb_reduce.csv",
                   kwargs...,
                   )
    return IMBReduce(
        Configuration(T; filename, kwargs...),
        "IMB Reduce",
    )
end

function imb_reduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    send_buffer = zeros(T, bufsize)
    recv_buffer = zeros(T, bufsize)
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        MPI.Reduce!(send_buffer, recv_buffer, +, comm)
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(bench::IMBReduce) = run_imb_collective(bench, imb_reduce, bench.conf)
