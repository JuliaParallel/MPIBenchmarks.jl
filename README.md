# MPIBenchmarks

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaParallel.github.io/MPIBenchmarks.jl/stable) -->
<!-- [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaParallel.github.io/MPIBenchmarks.jl/dev) -->
[![Build Status](https://github.com/JuliaParallel/MPIBenchmarks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaParallel/MPIBenchmarks.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaParallel/MPIBenchmarks.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaParallel/MPIBenchmarks.jl)

`MPIBenchmarks.jl` is a collection of benchmarks for `MPI.jl`, the
[Julia](https://julialang.org/) wrapper for the Message Passing Interface
([MPI](https://www.mpi-forum.org/)).

The goal is to have a suite of benchmarks which will allow `MPI.jl` users to

* compare performance of different MPI libraries used with `MPI.jl`;
* compare performance of `MPI.jl` with analogue benchmarks written in other languages, like
  C/C++.

For this purpose we have benchmarks inspired by [Intel(R) MPI
Benchmarks](https://www.intel.com/content/www/us/en/develop/documentation/imb-user-guide/top.html)
(IMB) and [OSU Micro-Benchmarks](http://mvapich.cse.ohio-state.edu/benchmarks/), to make it
easier to compare results with established MPI benchmarks suites.

_**NOTE: `MPIBenchmarks.jl` is a work in progress.  Contributions are very much welcome!**_

## Installation

To install `MPIBenchmarks.jl`, open a Julia REPL, type `]` to enter the Pkg REPL mode and
run the command

```
add https://github.com/JuliaParallel/MPIBenchmarks.jl
```

`MPIBenchmarks.jl` currently requires Julia v1.6 and `MPI.jl` v0.20.

## Usage

`MPIBenchmarks.jl` currently provides the following benchmark types

* collective
  * `IMBAllreduce()`: inspired by IMB Allreduce
  * `IMBReduce()`: inspired by IMB Reduce
* point-to-point:
  * `IMBPingPong()`: inspired by IMB PingPong

After loading the package

```julia
using MPIBenchmarks
```

to run a benchmark use the function `run(<BENCHMARK TYPE>)`, replacing `<BENCHMARK TYPE>`
with the name of the benchmark you want to run, from the list above.  The benchmarking types
take the following arguments:

* optional positional argument:
  * `T::Type`: data type to use for the communication.  It must be a bits type, with size in
	bytes which is a power of 2.  Default is `UInt8`
* keyword arguments:
  * `verbose::Bool`: whether to print to `stdout` some information.  Default is `true`.
  * `filename::Union{String,Nothing}`: name of the output CSV file where to save the results
	of the benchmark.  If `nothing`, the file is not written.  Default is a string with the
	name of the given benchmark (e.g., `"julia_imb_pingpong.csv"` for `IMBPingPong`).

### Example

Write a script like the following:

```julia
using MPIBenchmarks

run(IMBAllreduce())
run(IMBReduce())
run(IMBPingPong())
```

Then execute it with the following command

```
mpiexecjl -np 4 julia --project mpi_benchmarks.jl
```

where

* `mpiexecjl` is [Julia's wrapper for
  `mpiexec`](https://juliaparallel.org/MPI.jl/dev/usage/#Julia-wrapper-for-mpiexec),
* `4` is the number of MPI process to launch (use any other suitable number for your
  benchmarks, at least 2)
* `mpi_benchmarks.jl` is the name of the script you created.

## License

The `MPIBenchmarks.jl` package is licensed under the MIT "Expat" License.  The original
author is Mosè Giordano.
