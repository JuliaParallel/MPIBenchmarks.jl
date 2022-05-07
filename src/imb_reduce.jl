export IMBReduce

struct IMBReduce <: MPIBenchmark end

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

Base.run(::Type{IMBReduce}, conf::Configuration) =
    run_imb_collective(imb_reduce, conf)

Base.run(bench::Type{IMBReduce}; T::Type=UInt8, verbose::Bool=true, filename::Union{String,Nothing}="julia_imb_reduce.csv") =
    Base.run(bench, Configuration(T; verbose, filename))
