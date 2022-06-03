using Plots, DelimitedFiles

# Convert decimal Megabyte to binary Gibibyte
mb_to_gib(x) = x * (1e6 / (2 ^ 30))

function format_bytes(bytes)
    log2b = log2(bytes)
    unit, val = divrem(log2b, 10)
    val = Int(exp2(val))
    unit_string = if unit == 0
        " B"
    elseif unit == 1
        " KiB"
    elseif unit == 2
        " MiB"
    elseif unit == 3
        " GiB"
    elseif unit == 4
        " TiB"
    end
    return string(val) * unit_string
end

@doc raw"""
    plot_mpi(sytem::String, name::String;
             xlims=(1, 2 ^ 23),
             throughput::Bool=false,
             ref_file::Union{Nothing,String}="imb_$(lowercase(name)).csv",
             )

Do latency and throughput plots for the `name` benchmark.  `system` is the name
of the system where the benchmark was run, this is used in the title of the
plot.  `xlims` is the tuple of extrema of the x range of the plot (same syntax
as `xlims` in `Plots.jl`).  If `throughput` is `false`, the throughput plot is
omitted.  `ref_file` is the reference file, use `nothing` to indicate there is
no reference.
"""
function plot_mpi(sytem::String, name::String;
                  xlims=(1, 2 ^ 23),
                  throughput::Bool=false,
                  ref_file::Union{Nothing,String}="imb_$(lowercase(name)).csv",
                  )
    xticks_range = exp2.(log2(first(xlims)):2:log2(last(xlims)))
    xticks = (xticks_range, format_bytes.(xticks_range))

    julia = readdlm("julia_imb_$(lowercase(name)).csv", ',', Float64; skipstart=1)
    if !isnothing(ref_file)
        if isfile(ref_file)
            reference = readdlm(ref_file, ',', Float64; skipstart=1)
        else
            error("$(ref_file) is not a file")
        end
    end

    p = plot(;
             title = "Latency of MPI $(name) @ $(system)",
             xlabel = "message size",
             xscale = :log10,
             xlims,
             xticks,
             ylabel = "time [sec]",
             yscale = :log10,
             legend = :topleft,
             )
    plot!(p, julia[:, 1], julia[:, 3]; label="Julia (MPI.jl)", marker=:auto, markersize=3)
    if !isnothing(ref_file)
        plot!(p, reference[:, 1], reference[:, 3] .* 1e-6; label="C (IMB)", marker=:auto, markersize=3)
    end
    savefig("$(lowercase(name))-latency.pdf")

    if throughput
        p = plot(;
                 title = "Throughput of MPI $(name) @ $(system)",
                 xlabel = "message size",
                 xscale = :log10,
                 xlims,
                 xticks,
                 ylabel = "throughput [GiB/s]",
                 legend = :topleft,
                 )
        plot!(p, julia[:, 1], mb_to_gib.(julia[:, 4]); label="Julia (MPI.jl)", marker=:auto, markersize=3)
        if !isnothing(ref_file)
            plot!(p, reference[:, 1], mb_to_gib.(reference[:, 4]); label="C (IMB)", marker=:auto, markersize=3)
        end
        savefig("$(lowercase(name))-throughput.pdf")
    end

end

system = "UCL Kathleen"
plot_mpi(system, "PingPong")
plot_mpi(system, "PingPing"; ref_file=nothing)
plot_mpi(system, "AllReduce"; xlims=(4, 2 ^ 23), throughput=false, ref_file=nothing)
plot_mpi(system, "AllToAll"; xlims=(1, 2 ^ 21), throughput=false, ref_file=nothing)
plot_mpi(system, "Gatherv"; xlims=(1, 2 ^ 21), throughput=false, ref_file=nothing)
plot_mpi(system, "Reduce"; xlims=(4, 2 ^ 23), throughput=false, ref_file=nothing)
