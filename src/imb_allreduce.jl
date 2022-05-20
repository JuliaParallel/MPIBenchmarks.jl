export IMBAllreduce

struct IMBAllreduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBAllreduce(T::Type=Float32;
                      filename::Union{String,Nothing}="julia_imb_allreduce.csv",
                      kwargs...,
                      )
    return IMBAllreduce(
        Configuration(T; filename, kwargs...),
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

benchmark(bench::IMBAllreduce) = run_imb_collective(bench, imb_allreduce, bench.conf)
