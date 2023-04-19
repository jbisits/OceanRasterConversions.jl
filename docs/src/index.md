# OceanRasterConversions.jl documentation

[Rasters.jl](https://rafaqz.github.io/Rasters.jl/dev/) provides excellent methods for reading, analysing and plotting for geospatial data.
This package contains modules that are useful for analysing oceanic data (either model output or gridded observations) and is designed to be used in conjunction with Rasters.jl.
The modules are:

- [`OceanVariableConversions`](@ref ocean_conv_vars_module), conversion and computation (using [TEOS-10](https://www.teos-10.org/pubs/gsw/html/gsw_front_page.html)) of ocean variables that are `Raster` data structures; and
- [`RasterHistograms`](@ref raster_hist_module), empirical distribution fitting for `Raster` data structures aiming to provide functionality similar to python's [xhistogram](https://xhistogram.readthedocs.io/en/latest/index.html) for [xarray](https://docs.xarray.dev/en/stable/) in Julia.

If there are any bugs and/or feature request please raise an [issue](https://github.com/jbisits/OceanRasterConversions.jl/issues) on the GitHub page.

!!! info
    This package assumes that the `missingval = missing` in the `Raster`, `RasterStack` or `RasterSeries`.
    By default `missingval = missing` in Rasters.jl, so as long as the `missingval` has not been changed the modules in this package will work.
