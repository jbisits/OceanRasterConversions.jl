"""
Module to fit `Histogram`s to data that is saved as a `Raster`, `RasterStack` or
`RasterSeries`. The fitted `Histogram` will be N-dimensional, where N is the number of
layers (i.e. variables) to fit the `Histogram` to.
"""
module RasterHistograms

using Rasters, StatsBase, MakieCore, LinearAlgebra, DocStringExtensions, RecipesBase
import LinearAlgebra.normalize!
import MakieCore.convert_arguments
import DimensionalData.dim2key
import Base.show

export RasterLayerHistogram, RasterStackHistogram, RasterSeriesHistogram,
       area_weights, volume_weights, convert_arguments, normalize!

"Abstract supertype for a `RasterHistogram`."
abstract type AbstractRasterHistogram end

"""
    mutable struct RasterLayerHistogram <: AbstractRasterHistogram
A `RasterLayerHistogram`. The `struct` is `mutable` so that the `histogram` field can be
updated using the `normalize` (or otherwise) function.

$(TYPEDFIELDS)
"""
mutable struct RasterLayerHistogram <: AbstractRasterHistogram
    "The layer (variable) from the `Raster`"
        layer       :: Symbol
    "The dimensions of the `Raster`"
        dimensions  :: Tuple
    "The size of the `Raster`"
        raster_size :: Tuple
    "The 1-dimensional histogram fitted to the `Raster` layer data"
        histogram   :: AbstractHistogram
end
"""
    function RasterLayerHistogram(rs::Raster; nbins = nothing)
    function RasterLayerHistogram(rs::Raster, weights::AbstractWeights; nbins = nothing)
    function RasterLayerHistogram(rs::Raster, edges::AbstractVector)
    function RasterLayerHistogram(rs::Raster, weights::AbstractWeights, edges::AbstractVector)
Construct a `RasterLayerHistogram` from a `Raster`. The flattened `Raster` data, with the
`missing` values removed, is passed to the `fit(::Histogram)` function from
[StatsBase.jl](https://juliastats.org/StatsBase.jl/latest/empirical/) and a
`RasterLayerHistogram` type is returned.
"""
function RasterLayerHistogram(rs::Raster; nbins = nothing)

    rs = read(rs)
    layer = name(rs)
    dimensions = DimensionalData.dim2key(dims(rs))
    rs_size = size(rs)
    find_nm = @. !ismissing(rs)
    flattened_rs_data = collect(skipmissing(read(rs)[find_nm]))

    histogram = isnothing(nbins) ? StatsBase.fit(Histogram, flattened_rs_data) :
                                   StatsBase.fit(Histogram, flattened_rs_data; nbins)

    return RasterLayerHistogram(layer, dimensions, rs_size, histogram)

end
function RasterLayerHistogram(rs::Raster, weights::AbstractWeights; nbins = nothing)

    layer = name(rs)
    dimensions = DimensionalData.dim2key(dims(rs))
    rs_size = size(rs)
    find_nm = @. !ismissing(rs)
    find_nm_vec = reshape(find_nm, :)
    flattened_rs_data = collect(skipmissing(read(rs)[find_nm]))

    histogram = isnothing(nbins) ? StatsBase.fit(Histogram, flattened_rs_data,
                                                 weights[find_nm_vec]) :
                                   StatsBase.fit(Histogram, flattened_rs_data,
                                                 weights[find_nm_vec]; nbins)

    return RasterLayerHistogram(layer, dimensions, rs_size, histogram)

end
function RasterLayerHistogram(rs::Raster, edges::AbstractVector)

    layer = name(rs)
    dimensions = DimensionalData.dim2key(dims(rs))
    rs_size = size(rs)
    find_nm = @. !ismissing(rs)
    flattened_rs_data = collect(skipmissing(read(rs)[find_nm]))

    histogram = StatsBase.fit(Histogram, flattened_rs_data, edges)

    return RasterLayerHistogram(layer, dimensions, rs_size, histogram)

end
function RasterLayerHistogram(rs::Raster, weights::AbstractWeights, edges::AbstractVector)

    layer = name(rs)
    dimensions = DimensionalData.dim2key(dims(rs))
    rs_size = size(rs)
    find_nm = @. !ismissing(rs)
    find_nm_vec = reshape(find_nm, :)
    flattened_rs_data = collect(skipmissing(read(rs)[find_nm]))

    histogram = StatsBase.fit(Histogram, flattened_rs_data, weights[find_nm_vec], edges)

    return RasterLayerHistogram(layer, dimensions, rs_size, histogram)

end

"""
    mutable struct RasterStackHistogram <: AbstractRasterHistogram
A `RasterStackHistogram`. The `struct` is `mutable` so that the `histogram` field can be
updated using the `normalize` (or otherwise) function.

    $(TYPEDFIELDS)
"""
mutable struct RasterStackHistogram <: AbstractRasterHistogram
    "The layers (variables) from the `RasterStack` used to fit the `Histogram`"
        layers      :: Tuple
    "The dimensions of the `RasterStack`"
        dimensions  :: Tuple
    "The size of the `RasterStack` layers"
        raster_size :: Tuple
    "The N-dimensional `Histogram` fitted to the N layers from `RasterStack`"
        histogram   :: Histogram
end
"""
    function RasterStackHistogram(stack::RasterStack; nbins = nothing)
    function RasterStackHistogram(stack::RasterStack, weights::AbstractWeights; nbins = nothing)
    function RasterStackHistogram(stack::RasterStack, edges::NTuple{N, AbstractVector})
    function RasterStackHistogram(stack::RasterStack, weights::AbstractWeights,
                                  edges::NTuple{N, AbstractVector}
Construct a `RasterStackHistogram` from a `RasterStack`. The resulting `Histogram` is
N-dimensional, where N is the number of layers. The flattened `Raster` data for each layer,
with the`missing` values removed, is passed to the `fit(::Histogram)` function from
[StatsBase.jl](https://juliastats.org/StatsBase.jl/latest/empirical/) and a
`RasterStackHistogram` type is returned.
"""
function RasterStackHistogram(stack::RasterStack; nbins = nothing)

    layers = names(stack)
    dimensions = DimensionalData.dim2key(dims(stack))
    rs_size = size(stack)
    find_nm = find_stack_non_missing(stack)
    flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ stack)

    histogram = isnothing(nbins) ? StatsBase.fit(Histogram, flattened_stack_data) :
                                   StatsBase.fit(Histogram, flattened_stack_data; nbins)

    return RasterStackHistogram(layers, dimensions, rs_size, histogram)

end
function RasterStackHistogram(stack::RasterStack, weights::AbstractWeights; nbins = nothing)

    layers = names(stack)
    dimensions = DimensionalData.dim2key(dims(stack))
    rs_size = size(stack)
    find_nm = find_stack_non_missing(stack)
    find_nm_vec = reshape(find_nm, :)
    flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ stack)

    histogram = isnothing(nbins) ? StatsBase.fit(Histogram, flattened_stack_data,
                                                 weights[find_nm_vec]) :
                                   StatsBase.fit(Histogram, flattened_stack_data,
                                                 weights[find_nm_vec]; nbins)


    return RasterStackHistogram(layers, dimensions, rs_size, histogram)

end
function RasterStackHistogram(stack::RasterStack, edges::NTuple{N, AbstractVector}) where {N}

    layers = names(stack)
    dimensions = DimensionalData.dim2key(dims(stack))
    rs_size = size(stack)
    find_nm = find_stack_non_missing(stack)
    flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ stack)

    histogram = StatsBase.fit(Histogram, flattened_stack_data, edges)

    return RasterStackHistogram(layers, dimensions, rs_size, histogram)

end
function RasterStackHistogram(stack::RasterStack, weights::AbstractWeights,
                              edges::NTuple{N, AbstractVector}) where {N}

    layers = names(stack)
    dimensions = DimensionalData.dim2key(dims(stack))
    rs_size = size(stack)
    find_nm = find_stack_non_missing(stack)
    find_nm_vec = reshape(find_nm, :)
    flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ stack)

    histogram = StatsBase.fit(Histogram, flattened_stack_data, weights[find_nm_vec], edges)

    return RasterStackHistogram(layers, dimensions, rs_size, histogram)

end
"""
    mutable struct RasterSeriesHistogram <: AbstractRasterHistogram
A `RasterSeriesHistogram`. The `struct` is `mutable` so that the `histogram` field can be
updated using the `normalize` (or otherwise) function.

$(TYPEDFIELDS)
"""
mutable struct RasterSeriesHistogram <: AbstractRasterHistogram
    "The layers (variables) from the `RasterSeries` used to fit the `Histogram`"
        layers           :: Tuple
    "The dimension of the `RasterSeries` (usually this will be time)"
        series_dimension :: Symbol
    "The length of the `RasterSeries"
        series_length    :: Int64
    "The dimensions of the elements (either a `Raster` or `RasterStack`) of the `RasterSeries`"
        dimensions       :: Tuple
    "The size of the elements (either a `Raster` or `RasterStack`) of the `RasterSeries`"
        raster_size      :: Tuple
    "The N-dimensional `Histogram` fitted to the N layers from `RasterSeries`"
        histogram        :: Histogram
end
"""
    function RasterSeriesHistogram(series::RasterSeries, edges::NTuple{N, AbstractVector})
    function  RasterSeriesHistogram(series::RasterSeries, weights::AbstractWeights,
                                    edges::NTuple{N, AbstractVector})
Construct a `RasterSeriesHistogram` from a `RasterSeries`. Note that to `merge` `Histograms`
the bin edges must be the same, so for this constructor the edges must be passed in. This
constructor assumes that the dimensions are the same across all `RasterStack`s in the
`RasterSeries`.
"""
function RasterSeriesHistogram(series::RasterSeries, edges::NTuple{N, AbstractVector}) where {N}

    series_dimension = DimensionalData.dim2key(dims(series))[1]
    series_length = length(series)
    layers = names(series[1])
    dimensions = DimensionalData.dim2key(dims(series[1]))
    rs_size = size(series[1])
    find_nm = find_stack_non_missing(series[1])
    flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ series[1])

    histogram = StatsBase.fit(Histogram, flattened_stack_data, edges)

    for stack ∈ series[2:end]
        find_nm = find_stack_non_missing(stack)
        flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ stack)

        h = StatsBase.fit(Histogram, flattened_stack_data, edges)

        merge!(histogram, h)

    end

    return RasterSeriesHistogram(layers, series_dimension, series_length,
                                 dimensions, rs_size, histogram)

end
function  RasterSeriesHistogram(series::RasterSeries, weights::AbstractWeights,
                                edges::NTuple{N, AbstractVector}) where {N}

    series_dimension = DimensionalData.dim2key(dims(series))[1]
    series_length = length(series)
    layers = names(series[1])
    dimensions = DimensionalData.dim2key(dims(series[1]))
    rs_size = size(series[1])
    find_nm = find_stack_non_missing(series[1])
    find_nm_vec = reshape(find_nm, :)
    flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm])) for layer ∈ series[1])

    histogram = StatsBase.fit(Histogram, flattened_stack_data, weights[find_nm_vec], edges)

    for stack ∈ series[2:end]

        find_nm_ = find_stack_non_missing(stack)
        find_nm_vec_ = reshape(find_nm_, :)
        flattened_stack_data = Tuple(collect(skipmissing(read(layer)[find_nm_])) for layer ∈ stack)

        h = StatsBase.fit(Histogram, flattened_stack_data, weights[find_nm_vec_], edges)

        merge!(histogram, h)

    end

    return RasterSeriesHistogram(layers, series_dimension, series_length,
                                 dimensions, rs_size, histogram)

end
"""
    function find_stack_non_missing(stack::RasterStack)
Return a `Raster` of type `Bool` that contains the intersection of the non-`missing` values
from the layers of a `RasterStack`.
"""
function find_stack_non_missing(stack::RasterStack)

    nm_raster_vec = [.!ismissing.(stack[var]) for var ∈ keys(stack)]
    intersection_non_missings = nm_raster_vec[1]
    for nm_rs ∈ nm_raster_vec[2:end]
        intersection_non_missings = intersection_non_missings .&& nm_rs .== 1
    end

    return intersection_non_missings
end

function Base.show(io::IO, rlh::RasterLayerHistogram)
    println(io, "RasterLayerHistogram for the variable $(rlh.layer)")
    println(io, " ┣━━ Layer dimensions: $(rlh.dimensions) ")
    println(io, " ┣━━━━━━━━ Layer size: $(rlh.raster_size)")
    print(io,   " ┗━━━━━━━━━ Histogram: 1-dimensional")
end
function Base.show(io::IO, rsh::RasterStackHistogram)
    println(io, "RasterStackHistogram for the variables $(rsh.layers)")
    println(io, " ┣━━ Stack dimensions: $(rsh.dimensions)")
    println(io, " ┣━━ Stack layer size: $(rsh.raster_size)")
    print(io,   " ┗━━━━━━━━━ Histogram: $(length(rsh.layers))-dimensional")
end
function Base.show(io::IO, rseh::RasterSeriesHistogram)
    println(io, "RasterSeriesHistogram for the variables $(rseh.layers)")
    println(io, " ┣━━━━━━━━━━━━━━━━━━━━ Series dimension: $(rseh.series_dimension)")
    println(io, " ┣━━━━━━━━━━━━━━━━━━━━━━━ Series length: $(rseh.series_length)")
    println(io, " ┣━━ Data Dimensions of series elements: $(rseh.dimensions) ")
    println(io, " ┣━━━━━━━━ Data size of series elements: $(rseh.raster_size)")
    print(io,   " ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━ Histogram: $(length(rseh.layers))-dimensional")
end

"""
    function convert_arguments(P::Type{<:AbstractPlot}, arh::AbstractRasterHistogram)
Converting method so Makie.jl can plot an `AbstractRasterHistogram`. **Note** for plotting
purposes a value correspnding to zero is replaced with `NaN`. This is to avoid in 2D
plotting many zero values and as a result not seeing the distribtution clearly (in Makie.kj
`heatmap` the `NaN` value is
[left out in plotting](https://docs.makie.org/stable/examples/plotting_functions/heatmap/#three_vectors)).
"""
function MakieCore.convert_arguments(P::Type{<:MakieCore.AbstractPlot},
                                     arh::AbstractRasterHistogram,
                                     show_empty_bins::Bool=true)

    histogram_to_plot = show_empty_bins ? arh.histogram : raster_zeros_to_nan(arh)

    return convert_arguments(P, histogram_to_plot)

end

"""
    function raster_zeros_to_nan(arh::AbstractRasterHistogram)
Convert the `zero`s (i.e. empty bins in the `AbstractRasterHistogram`) to `NaN`s for
plotting in Makie.
"""
function raster_zeros_to_nan(arh::AbstractRasterHistogram)

    temp = float(arh.histogram)
    replace!(temp.weights, 0 => NaN)

    return temp

end

"Conversion method for plotting in Plots.jl"
@recipe f(::Type{<:AbstractRasterHistogram}, arh::AbstractRasterHistogram) = arh.histogram

"""
    function normalize!(arh::AbstractRasterHistogram; mode::Symbol = :pdf)
Normalize the `Histogram` in the `AbstractRasterHistogram` according the desired `mode`.
See the [StatsBase.jl docs](https://juliastats.org/StatsBase.jl/latest/empirical/#LinearAlgebra.normalize)
for information on the possible `mode`s and how they work.
"""
function LinearAlgebra.normalize!(arh::AbstractRasterHistogram; mode::Symbol = :pdf)

    arh.histogram = LinearAlgebra.normalize(arh.histogram; mode)

    return nothing

end

"""
    function area_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)
Return the `Weights` for a `Histogram` calculated from the area of each grid cell in a
`Raster` or `RasterStack`. The `Raster` or `RasterStack` must first be sliced over the
dimensions one wishes to look at, e.g. for area weights at sea surface the function need
`rs[Z(1)]` to be passed in. If the original `Raster` only has two spatial dimensions then
this step may be skipped.
The keyword argument `equator_one_degree` is one degree at the equator in metres.
The function returns a container `Weights` so can be passed straight into
the `fit(::Histogram)` function.
"""
function area_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)

    rs = typeof(rs) <: RasterStack ? rs[keys(rs)[1]] : rs

    dA = if !hasdim(rs, :Z)
             lon, lat = lookup(rs, X), lookup(rs, Y)
             lon_model_resolution = unique(diff(lon))[1]
             lat_model_resolution = unique(diff(lat))[1]
             dx = (equator_one_degree * lon_model_resolution) .* ones(length(lon))
             dy = (equator_one_degree * lat_model_resolution) .* cos.(deg2rad.(lat))
             hasdim(rs, Ti) ? repeat(reshape(dx * dy', :), outer = length(lookup(rs, Ti))) :
                              reshape(dx * dy', :)
         elseif !hasdim(rs, :Y)
             lon, z = lookup(rs, X), lookup(rs, Z)
             lon_model_resolution = unique(diff(lon))[1]
             dx = (equator_one_degree * lon_model_resolution) .* ones(length(lon))
             dz = diff(abs.(z))
             dz = vcat(dz[1], dz)
             hasdim(rs, Ti) ? repeat(reshape(dx * dz', :), outer = length(lookup(rs, Ti))) :
                              reshape(dx * dz', :)
         elseif !hasdim(rs, :X)
             lat, z = lookup(rs, Y), lookup(rs, Z)
             lat_model_resolution = unique(diff(lat))[1]
             dy = (equator_one_degree * lat_model_resolution) .* cos.(deg2rad.(lat))
             dz = diff(abs.(z))
             dz = vcat(dz[1], dz)
             hasdim(rs, Ti) ? repeat(reshape(dy * dz', :), outer = length(lookup(rs, Ti))) :
                              reshape(dy * dz', :)
         end

    return weights(dA)

end
"""
    function volume_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)
Return the `Weights` for a `Histogram` calculated from the volume of each grid cell in a
`Raster` or `RasterStack`. The model resolution is inferred from the `X` and `Y` dimensions
of the `Raster` or `RasterStack` and assumes that along the `X` and `Y` the resolution is
unique (though it can be different for `X` and `Y`).
The keyword argument `equator_one_degree` is one degree at the
equator in metres. The function returns a container `Weights` so can be passed straight into
the `fit(::Histogram)` function.
"""
function volume_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)

    rs = typeof(rs) <: RasterStack ? rs[keys(rs)[1]] : rs
    lon, lat, z = lookup(rs, X), lookup(rs, Y), lookup(rs, Z)
    lon_model_resolution = unique(diff(lon))[1]
    lat_model_resolution = unique(diff(lat))[1]
    dx = (equator_one_degree * lon_model_resolution) .* ones(length(lon))
    dy = (equator_one_degree * lat_model_resolution) .* cos.(deg2rad.(lat))
    dz = diff(abs.(z))
    dz = vcat(dz[1], dz)
    dV = Array{Float64}(undef, length(dx), length(dy), length(dz))
    for i ∈ axes(dV, 3)
        dV[:, :, i] = (dx .* dy') * dz[i]
    end
    dV_vec = hasdim(rs, Ti) ? repeat(reshape(dV, :), outer = length(lookup(rs, Ti))) :
                              reshape(dV, :)

    return weights(dV_vec)

end

end # module
