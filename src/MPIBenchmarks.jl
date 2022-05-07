module MPIBenchmarks

using MPI

abstract type MPIBenchmark end

struct Configuration{T}
    T::Type{T}
    lengths::UnitRange{Int}
    iters::Function
    stdout::IO
    filename::Union{String,Nothing}
end

function Configuration(T::Type;
                       stdout::Union{IO,Nothing}=nothing,
                       verbose::Bool=true,
                       filename::Union{String,Nothing}=nothing,
                       )
    isprimitivetype(T) || throw(ArgumentError("Type $(T) is not a primitive type"))
    size = sizeof(T)
    ispow2(size) || throw(ArgumentError("Type $(T) must have size which is a power of 2, found $(size)"))
    log2size = Int(log2(sizeof(T)))
    # We want to send minimum 0 bytes, maximum 4 MiB.  Maximim lenght is then 2 ^ (22 - log2size)
    lengths = -1:(22 - log2size)
    iters(s::Int) = s < (16 - log2size) ? 1000 : (640 >> (s - (16 - log2size)))
    if isnothing(stdout)
        stdout = verbose ? Base.stdout : Base.devnull
    end
    return Configuration(T, lengths, iters, stdout, filename)
end

include("imb_collective.jl")
include("imb_p2p.jl")

end
