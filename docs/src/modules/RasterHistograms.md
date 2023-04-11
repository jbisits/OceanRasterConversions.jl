# RasterHistograms

This module uses [empirical estimation from StatsBase.jl](https://juliastats.org/StatsBase.jl/stable/empirical/) to fit `Histogram`s to `Raster`, `RasterStack` or `RasterSeries` data structures.
The functions take in the `Raster` data structure, as well as arguments for the `Histogram` (e.g. weights, edges).
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

```@meta
DocTestSetup = nothing
```

## Functions exported from `RasterHistograms`

```@docs
RasterLayerHistogram
RasterStackHistogram
RasterSeriesHistogram
area_weights
volume_weights
```
