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

function osu_allreduce(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, off_cache::Int64)
    cache_size =  off_cache # Required in Bytes
    num_buffers = max(1, 2 * cache_size ÷ max(1, (sizeof(T) * bufsize)))
    send_buffer = [ones(T, bufsize) for _ in 1:num_buffers]
    recv_buffer = [zeros(T, bufsize) for _ in 1:num_buffers]
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Allreduce!(@inbounds(send_buffer[mod1(i, num_buffers)]), @inbounds(recv_buffer[mod1(i, num_buffers)]), +, comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUAllreduce) = run_osu_collective(bench, osu_allreduce, bench.conf)
