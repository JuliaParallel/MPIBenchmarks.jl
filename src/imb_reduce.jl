export IMBReduce

struct IMBReduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function IMBReduce(T::Type=Float32;
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
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Reduce!(send_buffer, recv_buffer, +, comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::IMBReduce) = run_imb_collective(bench, imb_reduce, bench.conf)
