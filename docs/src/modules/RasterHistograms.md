# [RasterHistograms](@id raster_hist_module)

## Overview

This module uses [empirical estimation from StatsBase.jl](https://juliastats.org/StatsBase.jl/stable/empirical/) to fit `Histogram`s to `Raster`, `RasterStack` or `RasterSeries` data structures.
Arguments that can be passed to [`fit(::Histogram)`](https://juliastats.org/StatsBase.jl/stable/empirical/#StatsAPI.fit-Tuple{Type{Histogram},%20Vararg{Any}}) can be passed to the constructors for the the various `AbstractRasterHistogram`s.
The aim of the module is to provide functionality similar to python's [xhistogram](https://xhistogram.readthedocs.io/en/latest/index.html) for [xarray](https://docs.xarray.dev/en/stable/) in Julia.

## Module workings

For a single `Raster` (i.e. one variable)

```@meta
DocTestSetup = quote
    using Rasters, OceanRasterConversions.RasterHistograms
end
```

```jldoctest
julia> dummy_data = repeat(1:10; outer = (1, 10));

julia> rs = Raster(dummy_data, (X(1:10), Ti(1:10)); name = :dummy_variable);

julia> rs_hist = RasterLayerHistogram(rs)
RasterLayerHistogram for the variable dummy_variable
 ┣━━ Layer dimensions: (:X, :Ti) 
 ┣━━━━━━━━ Layer size: (10, 10)
 ┗━━━━━━━━━ Histogram: 1-dimensional

julia> rs_hist.histogram
StatsBase.Histogram{Int64, 1, Tuple{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}}}
edges:
  0.0:2.0:12.0
weights: [10, 20, 20, 20, 20, 10]
closed: left
isdensity: false

```

a one dimensional `Histogram` that has been fit to the `dumy_variable` data is returned in the `rs_hist.histogram` field as well as some information about the data the `Histogram` was fit to.
If a `RasterStack` or `RasterSeries` with multiple layers is passed in the default behaviour is to fit an N-dimensional `Histogram` where N is the number of layers (i.e. the number of variables).

```jldoctest
julia> vars = (v1 = randn(10, 10), v2 = randn(10, 10), v3 = randn(10, 10));

julia> stack = RasterStack(vars, (X(1:10), Y(1:10)))
RasterStack with dimensions: 
  X Sampled{Int64} 1:10 ForwardOrdered Regular Points,
  Y Sampled{Int64} 1:10 ForwardOrdered Regular Points
and 3 layers:
  :v1 Float64 dims: X, Y (10×10)
  :v2 Float64 dims: X, Y (10×10)
  :v3 Float64 dims: X, Y (10×10)


julia> RasterStackHistogram(stack)
RasterStackHistogram for the variables (:v1, :v2, :v3)
 ┣━━ Stack dimensions: (:X, :Y)
 ┣━━ Stack layer size: (10, 10)
 ┗━━━━━━━━━ Histogram: 3-dimensional

```

!!! info
    The order of the variables for the `Histogram` is the order of the layers in the `RasterStack` or `RasterSeries`. This can be important for plotting when variables are desired to be on specific axes. In the example above `v1` would be on the x-axis, `v2` the y-axis and `v3` the z-axis. To change which axes the variables correspond to, the order of the layers in the `RasterStack` would need to be altered (or you could plot from the `histogram.weights` matrix).

```@meta
DocTestSetup = nothing
```

## Plotting

Both [Makie.jl](https://docs.makie.org/stable/) and [Plots.jl](https://docs.juliaplots.org/stable/) have functions in the module to extract the `Histogram` object from the `AbstractRasterHistogram` for plotting.
To plot in either package one can just call

```julia
julia> using #Plotting package e.g. CairoMakie.jl or PLots.jl 

julia> plot(::AbstractRasterHistogram)
```

and an N-dimensional `Histogram` will be plotted where N is the dimension of the `::AbstractRasterHistogram`.
Makie.jl is used in the exmaple.

For a full list of the functions in this module see the [function index](@ref rh_func_index) or look at the [example](@ref raster_hist_example) to see the module in action.
