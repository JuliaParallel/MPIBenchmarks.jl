## `MPI.jl` benchmarks on Riken-CCS Fugaku

This directory contains some results of benchmarks run on [Riken-CCS
Fugaku](https://www.r-ccs.riken.jp/en/fugaku/).  Point-to-point benchmarks were run with 2
MPI processes on 2 nodes, collective benchmarks were run wih 1536 MPI evenly distributed on
384 nodes, with layout `4x6x16:torus:strict-io`.  More up-to-date benchmarks may be found in
the repository [`giordano/julia-on-fugaku`](https://github.com/giordano/julia-on-fugaku),
which also contains the submissions scripts to run the benchmarks, and the Julia scripts
used to do the plots.
