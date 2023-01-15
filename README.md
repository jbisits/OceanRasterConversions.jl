# OceanRasterConversions.jl

[![Doc dev badge](https://img.shields.io/badge/docs-dev-blue.svg)](https://jbisits.github.io/OceanRasterConversions.jl/dev/)
[![Build Status](https://github.com/jbisits/OceanRasterConversions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jbisits/OceanRasterConversions.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/jbisits/OceanRasterConversions.jl/branch/main/graph/badge.svg?token=XEAWB8IHFV)](https://codecov.io/gh/jbisits/OceanRasterConversions.jl)

This package converts and computes ocean varaibles that are saved as `Raster` data structures using [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl).
[Rasters.jl](https://github.com/rafaqz/Rasters.jl) provides excellent reading, writing and manipulation of geospatial data.
Typically, the salt and temperature variables from ocean models or observational data are practical salinity and potential temperature so conversions must be to the TEOS-10 standard variables of absolute salinity and conservative temperature to accurately calculate further variables like seawater density.

## Using the package
