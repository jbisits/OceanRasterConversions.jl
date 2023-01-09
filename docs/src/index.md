# OceanRasterConversions.jl documentation

## Overview

This package converts ocean varaibles that are saved as `Raster` data structures using [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl).
[Rasters.jl](https://github.com/rafaqz/Rasters.jl) provides excellent reading, writing and manipulation of geospatial data.
Typically, the salt and temperature variables from ocean models or observational data are practical salinity and potential temperature so conversions must be to the TEOS-10 standard variables of absolute salinity and conservative temperature to accurately calculate further variables like seawater density.

## Package workings

## Functions exported from `OceanRasterConversions`

```@docs
convert_ocean_vars
depth_to_pressure
Sₚ_to_Sₐ
θ_to_Θ
```
