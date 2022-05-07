export IMBReduce

struct IMBReduce <: MPIBenchmark
    name::String
    default_filename::String
end
IMBReduce() = IMBReduce("IMB Reduce", "julia_imb_reduce.csv")

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

Base.run(bench::IMBReduce, conf::Configuration) =
    run_imb_collective(bench, imb_reduce, conf)
