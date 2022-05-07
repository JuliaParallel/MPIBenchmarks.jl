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
                       max_size::Int=1 << 22,
                       stdout::Union{IO,Nothing}=nothing,
                       verbose::Bool=true,
                       filename::Union{String,Nothing}=nothing,
                       )
    ispow2(max_size) || throw(ArgumentError("Maximum size must be a power of 2, found $(max_size)"))
    isprimitivetype(T) || throw(ArgumentError("Type $(T) is not a primitive type"))
    size = sizeof(T)
    ispow2(size) || throw(ArgumentError("Type $(T) must have size which is a power of 2, found $(size)"))
    max_size > size || throw(ArgumentError("Maximum size in bytes ($(max_size)) must be larger than size of the data type in bytes $(size)"))
    log2size = Int(log2(sizeof(T)))
    last_length = Int(log2(max_size))
    lengths = -1:(last_length - log2size)
    iters(s::Int) = s < (16 - log2size) ? 1000 : (640 >> (s - (16 - log2size)))
    if isnothing(stdout)
        stdout = verbose ? Base.stdout : Base.devnull
    end
    return Configuration(T, lengths, iters, stdout, filename)
end

include("imb_collective.jl")
include("imb_p2p.jl")

end
