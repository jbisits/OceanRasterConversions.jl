# OceanRasterConversions

[![Build Status](https://github.com/jbisits/OceanRasterConversions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jbisits/OceanRasterConversions.jl/actions/workflows/CI.yml?query=branch%3Amain)

[Rasters.jl](https://github.com/rafaqz/Rasters.jl) provides excellent reading, writing and manipulation of geospatial data.
Typically, ocean variables are stored as practical salinity and potential temperature so conversions must be to the TEOS-10 standard variables of absolute salinity and conservative temperature using[GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl).
This package converts ocean varibles that are saved in `Raster`s to the TEOS-10 standard using [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl).
