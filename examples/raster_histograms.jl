# # [Raster Histograms](@id raster_hist_example)
# First, add the required depedencies
using Rasters, Downloads, CairoMakie
# and the `RasterHistograms` module from OceanRasterConversions.jl package
using OceanRasterConversions.RasterHistograms
# Using this module we can produce `Histogram`s from data that is in a `Raster`,
# `RasterStack` or `RasterSeries`, which are N-dimensional arrays, in a similar way that
# [xhistogram](https://xhistogram.readthedocs.io/en/latest/index.html) works for xarray
# in python. This example is structured similarly to the
# [xhistogram tutorial](https://xhistogram.readthedocs.io/en/latest/tutorial.html).
# ## Randomly generated toy data
# First we generate some randomly distributed data and form a `Raster`.
x, t = range(-2π, 2π; length = 50), range(-2π, 2π; length = 100)
dimensions = (X(x), Ti(t))
rs = Raster(randn(length(x), length(t)), dimensions; name = :Toy_data)
# The we can form a `RasterLayerHistogram` for the `:Toy_data`
rs_hist = RasterLayerHistogram(rs)
# We can then plot the data and the `Histogram`
fig = Figure(size = (1000, 600))
ax1 = Axis(fig[1, 1];
           title = "Toy data",
           xlabel = "x",
           ylabel = "time")
hm = heatmap!(ax1, x, t, rs.data)
Colorbar(fig[2, 1], hm; vertical = false, flipaxis = false)
ax2 = Axis(fig[1, 2];
          title = "Histogram of Toy data",
          xlabel = "Toy data", ylabel = "Counts")
plot!(ax2, rs_hist; color = :steelblue)
fig
# By default the `Histogram` has the counts in each bin. We can normalise the `Histogram`
# by calling the `normalize!` function on `rs_hist` and choosing a `mode` of normalisation.
# For more information about the possible modes of normalisation
# [see here](https://juliastats.org/StatsBase.jl/latest/empirical/#LinearAlgebra.normalize).
normalize!(rs_hist; mode = :pdf)
# Then replot with the normalised histogram
fig = Figure(size = (900, 600))
ax1 = Axis(fig[1, 1];
           title = "Toy data",
           xlabel = "x",
           ylabel = "time")
hm = heatmap!(ax1, x, t, rs.data)
Colorbar(fig[2, 1], hm; vertical = false, flipaxis = false)
ax2 = Axis(fig[1, 2];
          title = "Histogram (pdf) of Toy data",
          xlabel = "Toy data", ylabel = "density")
plot!(ax2, rs_hist; color = :steelblue)
fig
# ## Real world data example
# This package is mainly concerned with ocean variables, so we now look at temperature and
# salinity distributions from the same ECCO temperature and salinity data we look at in
# the [converting ocean variables](@ref converting_variables_example) example.
# This example also shows how the module works for 2-dimensional `Histograms` though it can
# be generalised to N dimensions depending on the number of variables
# (i.e. layers in the `RasterStack`) one is looking at.
# ### Forming the `RasterStack`
# We form a `RasterStack` with only the `:SALT` (practical salinity) and `:THETA`
# (potential temperature) layers. This means the resulting `RasterStackHistogram` will be 2
# dimensional. Note the order of the variables matters here for plotting purposes. The first
# layer, in this case `:SALT` will be the x-axis, and the second layer `:THETA` will be
# the y-axis.
stack_TS = RasterStack("ECCO_data.nc"; name = (:SALT, :THETA))
edges = (31:0.025:38, -2:0.1:32)
stack_hist = RasterStackHistogram(stack_TS, edges)
# Now we can plot, the histogram and look at the unweighted distribtution of temperature and
# salinity
fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (unweighted)",
          xlabel = "Practical salinity (°C)",
          ylabel = "Potential temperature (psu)")
hm = heatmap!(ax, stack_hist;
              colorrange = (1, maximum(stack_hist.histogram.weights)),
              lowclip = :white)
Colorbar(fig[1, 2], hm)
fig
# Currently there is no `log10` colourscale for a `heatmap` in Makie.jl (though it looks
# like it will be [here soon](https://github.com/MakieOrg/Makie.jl/pull/2493)) so to view
# the data on a `log10` scale we can extract the data from the `stack_hist.histogram`,
# transform the weights and then plot
fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (unweighted, log10 colourscale)",
          xlabel = "Practical salinity (°C)",
          ylabel = "Potential temperature (psu)")
hm = heatmap!(ax, stack_hist.histogram.edges..., log10.(stack_hist.histogram.weights);
              colorrange = (0, 5),
              lowclip = :white)
Colorbar(fig[1, 2], hm)
fig
# ### Weighting the `Histogram`
# The module also exports simple functions for calculating area and volume weights from the
# dimensions of the grid and plot the data. Where weights are available from model data they
# should be used in favour of the functions.
dV = volume_weights(stack_TS)
weighted_stack_hist = RasterStackHistogram(stack_TS, dV, edges)
fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (weighted)",
          xlabel = "Practical salinity (°C)",
          ylabel = "Potential temperature (psu)")
hm = heatmap!(ax, weighted_stack_hist;
              colorrange = (1, maximum(weighted_stack_hist.histogram.weights)),
              lowclip = :white)
Colorbar(fig[1, 2], hm)
fig
# Again to view on a `log10` scale we extract the data and transform
fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (weighted by volume, log10 colourscale)",
          xlabel = "Practical salinity (°C)",
          ylabel = "Potential temperature (psu)")
hm = heatmap!(ax, weighted_stack_hist.histogram.edges...,
              log10.(weighted_stack_hist.histogram.weights);
              colorrange = (11, 16),
              lowclip = :white)
Colorbar(fig[1, 2], hm)
fig
