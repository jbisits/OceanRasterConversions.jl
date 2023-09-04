# OceanRasterConversions.jl

[![Doc stable badge](https://img.shields.io/badge/docs-stable-blue.svg)](https://jbisits.github.io/OceanRasterConversions.jl/stable/)
[![Doc dev badge](https://img.shields.io/badge/docs-dev-blue.svg)](https://jbisits.github.io/OceanRasterConversions.jl/dev/)
[![Build Status](https://github.com/jbisits/OceanRasterConversions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jbisits/OceanRasterConversions.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/jbisits/OceanRasterConversions.jl/branch/main/graph/badge.svg?token=XEAWB8IHFV)](https://codecov.io/gh/jbisits/OceanRasterConversions.jl)

[Rasters.jl](https://rafaqz.github.io/Rasters.jl/dev/) provides excellent methods for reading, analysing and plotting for geospatial data.
[`OceanVariableConversions`](https://jbisits.github.io/OceanRasterConversions.jl/stable), provides conversion and computation (using [TEOS-10](https://www.teos-10.org/pubs/gsw/html/gsw_front_page.html)) of ocean variables that are `Raster` data structures.

## Using the package

The package is installed using Julia's package manager

```julia
julia> ]
(@v1.8) pkg> add OceanRasterConversions
```

then press `backspace` to exit the package manager.
To start using the package you will also need to have [Rasters.jl](https://github.com/rafaqz/Rasters.jl) installed (in the same manner as above but replace `OceanRasterConversions` with `Rasters`).
To then use the packages type

```julia
julia> using Rasters, OceanRasterConversions
```

into the repl.
