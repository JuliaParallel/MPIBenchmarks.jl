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
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Allreduce!(send_buffer, recv_buffer, +, comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBAllreduce) = run_imb_collective(bench, imb_allreduce, bench.conf)
