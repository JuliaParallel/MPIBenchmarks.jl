## `MPI.jl` benchmarks on UCL Kathleen

This directory contains some results of benchmarks run on [UCL
Kathleen](https://www.rc.ucl.ac.uk/docs/Clusters/Kathleen/) cluster.  Point-to-point
benchmarks were run with 2 MPI processes on 2 nodes, collective benchmarks were run with 60
MPI processes on 15 nodes.  Files with name starting with `julia_*` are from
`MPIBenchmarks.jl`, the files with name starting with `imb_*` are the results of the [Intel
MPI
Benchmarks](https://www.intel.com/content/www/us/en/develop/documentation/imb-user-guide/top.html),
used as reference in the plot.

The included [`plot.jl`](./plot.jl) file shows an example of script for plotting the results
of the benchmarks.  _**NOTE**_: this is purely indicative of how you can plot the data, but
it is not meant for general consumption.  The script makes a few assumptions, for example
about how the data had been written in the CSV files, which may not apply to your case.
