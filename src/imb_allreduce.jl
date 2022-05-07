export IMBAllreduce

struct IMBAllreduce <: MPIBenchmark
    name::String
    default_filename::String
end
IMBAllreduce() = IMBAllreduce("IMB Allreduce", "julia_imb_allreduce.csv")

function imb_allreduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    send_buffer = zeros(T, bufsize)
    recv_buffer = zeros(T, bufsize)
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        MPI.Allreduce!(send_buffer, recv_buffer, +, comm)
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(bench::IMBAllreduce, conf::Configuration) =
    run_imb_collective(bench, imb_allreduce, conf)
