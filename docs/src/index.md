# OceanRasterConversions.jl documentation

[Rasters.jl](https://rafaqz.github.io/Rasters.jl/dev/) provides excellent methods for reading, analysing and plotting for geospatial data.
This package contains modules that are useful for analysing oceanic data (either model output or gridded observations) and is designed to be used in conjunction with Rasters.jl.

OceanRasterConversions.jl converts and computes ocean varaibles that are saved as `Raster` data structures using [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl).
Typically, the salt and temperature variables from ocean models or observational data are practical salinity and potential temperature so conversions must be to the [TEOS-10](https://www.teos-10.org/pubs/gsw/html/gsw_front_page.html) standard variables of absolute salinity and conservative temperature to accurately calculate further variables like seawater density.
Further conversions and other water mass transformation procedures will be added in the future.

If there are any bugs and/or feature request please raise an [issue](https://github.com/jbisits/OceanRasterConversions.jl/issues) on the GitHub page.

!!! info
    This package assumes that the `missingval = missing` in the `Raster`, `RasterStack` or `RasterSeries`.
    By default `missingval = missing` in Rasters.jl, so as long as the `missingval` has not been changed the modules in this package will work.
