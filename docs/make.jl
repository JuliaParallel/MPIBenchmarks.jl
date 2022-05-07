using MPIBenchmarks
using Documenter

DocMeta.setdocmeta!(MPIBenchmarks, :DocTestSetup, :(using MPIBenchmarks); recursive=true)

makedocs(;
    modules=[MPIBenchmarks],
    authors="Mosè Giordano <mose@gnu.org> and contributors",
    repo="https://github.com/JuliaParallel/MPIBenchmarks.jl/blob/{commit}{path}#{line}",
    sitename="MPIBenchmarks.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaParallel.github.io/MPIBenchmarks.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaParallel/MPIBenchmarks.jl",
    devbranch="main",
)
