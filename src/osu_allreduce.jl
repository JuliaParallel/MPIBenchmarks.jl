export OSUAllreduce

struct OSUAllreduce <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUAllreduce(T::Type=Float32;
                      filename::Union{String,Nothing}="julia_osu_allreduce.csv",
                      kwargs...,
                      )
    return OSUAllreduce(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Allreduce",
    )
end

function osu_allreduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    send_buffer = ones(T, bufsize)
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

benchmark(bench::OSUAllreduce) = run_osu_collective(bench, osu_allreduce, bench.conf)
