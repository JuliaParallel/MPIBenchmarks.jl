export OSUAlltoall

struct OSUAlltoall <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSUAlltoall(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_osu_alltoall.csv",
                     kwargs...,
                     )
    return OSUAlltoall(
        Configuration(T; filename, max_size=2 ^ 20, kwargs...),
        "OSU Alltoall",
    )
end

function osu_alltoall(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm, off_cache::Int64)
    cache_size =  off_cache # Required in Bytes
    num_buffers = max(1, 2 * cache_size ÷ max(1, (sizeof(T) * bufsize)))    
    nranks = MPI.Comm_size(comm)
    send_buffer = [ones(T, bufsize * nranks) for _ in 1:num_buffers]
    recv_buffer = [zeros(T, bufsize * nranks) for _ in 1:num_buffers]
    timer = 0.0
    MPI.Barrier(comm)
    for i in 1:iters
        tic = MPI.Wtime()
        MPI.Alltoall!(
            UBuffer(@inbounds(send_buffer[mod1(i, num_buffers)]), Cint(bufsize), Cint(nranks), MPI.Datatype(T)),
            UBuffer(@inbounds(recv_buffer[mod1(i, num_buffers)]), Cint(bufsize), Cint(nranks), MPI.Datatype(T)),
            comm)
        toc = MPI.Wtime()
        timer += toc - tic
    end
    avgtime = timer / iters
    return avgtime
end

benchmark(bench::OSUAlltoall) = run_osu_collective(bench, osu_alltoall, bench.conf)
