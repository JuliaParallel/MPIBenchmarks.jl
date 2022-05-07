export IMBAllreduce

struct IMBAllreduce <: MPIBenchmark end

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

Base.run(::Type{IMBAllreduce}, conf::Configuration) =
    run_imb_collective(imb_allreduce, conf)

Base.run(bench::Type{IMBAllreduce}; T::Type=UInt8, verbose::Bool=true, filename::Union{String,Nothing}="julia_imb_allreduce.csv") =
    Base.run(bench, Configuration(T; verbose, filename))
