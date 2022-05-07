module MPIBenchmarks

using MPI

abstract type MPIBenchmark end

struct Configuration{T,R<:AbstractVector{Int}}
    T::Type{T}
    lengths::R
    iters::Function
    verbose::Bool
    filename::Union{String,Nothing}
end

function Configuration(T::Type;
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
    return Configuration(T, lengths, iters, verbose, filename)
end

include("imb_collective.jl")
include("imb_p2p.jl")

end
