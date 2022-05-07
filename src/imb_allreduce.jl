export IMBAllreduce

struct IMBAllreduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBAllreduce(T::Type=UInt8;
                      verbose::Bool=true,
                      filename::Union{String,Nothing}="julia_imb_allreduce.csv",
                      )
    return IMBAllreduce(
        Configuration(T; verbose, filename),
        "IMB Allreduce",
    )
end

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

Base.run(bench::IMBAllreduce) = run_imb_collective(bench, imb_allreduce, bench.conf)
