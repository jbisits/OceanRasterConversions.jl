using Rasters, Downloads, CairoMakie

using OceanRasterConversions.RasterHistograms

x, t = range(-2π, 2π; length = 50), range(0, 4π; length = 100)
dimensions = (X(x), Ti(t))
rs = Raster(randn(length(x), length(t)), dimensions; name = :Toy_data)

rs_hist = RasterLayerHistogram(rs)

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

normalize!(rs_hist; mode = :pdf)

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

stack_TS = RasterStack("ECCO_data.nc"; name = (:SALT, :THETA))
edges = (31:0.025:38, -2:0.1:32)
stack_hist = RasterStackHistogram(stack_TS, edges)

fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (unweighted)",
          xlabel = "Practical salinity (psu)",
          ylabel = "Potential temperature (°C)")
show_empty_bins = false
hm = heatmap!(ax, stack_hist, show_empty_bins)
Colorbar(fig[1, 2], hm)
fig

fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (unweighted, log10 colourscale)",
          xlabel = "Practical salinity (psu)",
          ylabel = "Potential temperature (°C)")
hm = heatmap!(ax, stack_hist.histogram.edges..., log10.(stack_hist.histogram.weights);
              colorrange = (0, 5),
              lowclip = :white)
Colorbar(fig[1, 2], hm)
fig

dV = volume_weights(stack_TS)
weighted_stack_hist = RasterStackHistogram(stack_TS, dV, edges)
fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (weighted)",
          xlabel = "Practical salinity (psu)",
          ylabel = "Potential temperature (°C)")
hm = heatmap!(ax, weighted_stack_hist, show_empty_bins)
Colorbar(fig[1, 2], hm)
fig

fig = Figure(size = (500, 500))
ax = Axis(fig[1, 1];
          title = "Temperature and salinity joint distribution (weighted by volume, log10 colourscale)",
          xlabel = "Practical salinity (psu)",
          ylabel = "Potential temperature (°C)")
hm = heatmap!(ax, weighted_stack_hist.histogram.edges...,
              log10.(weighted_stack_hist.histogram.weights);
              colorrange = (11, 16),
              lowclip = :white)
Colorbar(fig[1, 2], hm)
fig

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

