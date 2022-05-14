module MPIBenchmarks

using MPI

abstract type MPIBenchmark end
export benchmark

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
                       class::Symbol=:imb,
                       )
    ispow2(max_size) || throw(ArgumentError("Maximum size must be a power of 2, found $(max_size)"))
    isprimitivetype(T) || throw(ArgumentError("Type $(T) is not a primitive type"))
    size = sizeof(T)
    ispow2(size) || throw(ArgumentError("Type $(T) must have size which is a power of 2, found $(size)"))
    max_size > size || throw(ArgumentError("Maximum size in bytes ($(max_size)) must be larger than size of the data type in bytes $(size)"))
    log2size = Int(log2(sizeof(T)))
    last_length = Int(log2(max_size))
    lengths = -1:(last_length - log2size)
    function iters(s::Int)
        if class === :osu_collective
            s < (15 - log2size) ? 1_000 : 100
        elseif class === :osu_p2p
            s < (13 - log2size) ? 10_000 : 1_000
        else # assume class === :imb
            s < (16 - log2size) ? 1_000 : (640 >> (s - (16 - log2size)))
        end
    end
    if isnothing(stdout)
        stdout = verbose ? Base.stdout : Base.devnull
    end
    return Configuration(T, lengths, iters, stdout, filename)
end

"""
    benchmark(b::MPIBenchmark)

Execute the MPI benchmark `b`.
"""
function benchmark end

include("imb_collective.jl")
include("imb_p2p.jl")

include("osu_collective.jl")
include("osu_p2p.jl")

end
