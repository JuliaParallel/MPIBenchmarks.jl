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
    synchronization_option::Union{String,Nothing}
    window_size::Union{Int64,Nothing}
end

function iterations(::Type{T}, s::Int) where {T}
    log2size = trailing_zeros(sizeof(T))
    return 1 << ((s < 10 - log2size) ? (20 - log2size) : (30 - 2 * log2size - s))
end

function Configuration(T::Type;
                       max_size::Int=1 << 22,
                       stdout::Union{IO,Nothing}=nothing,
                       verbose::Bool=true,
                       filename::Union{String,Nothing}=nothing,
                       iterations::Function=iterations,
                       synchronization_option::Union{String,Nothing}="lock",
                       window_size::Union{Int64,Nothing}=64
                       )
    ispow2(max_size) || throw(ArgumentError("Maximum size must be a power of 2, found $(max_size)"))
    isprimitivetype(T) || throw(ArgumentError("Type $(T) is not a primitive type"))
    size = sizeof(T)
    ispow2(size) || throw(ArgumentError("Type $(T) must have size which is a power of 2, found $(size)"))
    max_size > size || throw(ArgumentError("Maximum size in bytes ($(max_size)) must be larger than size of the data type in bytes $(size)"))
    # We know `size` is a power of 2, so we can use
    # `trailing_zeros` to get its base-2 logarithm.
    log2size = trailing_zeros(size)
    last_length = Int(log2(max_size))
    lengths = -1:(last_length - log2size)
    if isnothing(stdout)
        stdout = verbose ? Base.stdout : Base.devnull
    end
    return Configuration(T, lengths, iterations, stdout, filename, synchronization_option, window_size)
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

include("osu_one_sided.jl")

end
