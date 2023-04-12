# test values
test_hist_edges = (33:0.025:38, -2:0.1:20)
test_hist_weights = weights(randn(size(rs_stack[:Sₚ])))
test_nbins = 200

# Single `Raster`
# RasterLayerHistograma
raster_hist = RasterLayerHistogram(rs_stack[:Sₚ])
raster_hist_nb = RasterLayerHistogram(rs_stack[:Sₚ]; nbins = test_nbins)
raster_hist_w = RasterLayerHistogram(rs_stack[:Sₚ], test_hist_weights)
raster_hist_wnb = RasterLayerHistogram(rs_stack[:Sₚ], test_hist_weights; nbins = test_nbins)
raster_hist_e = RasterLayerHistogram(rs_stack[:Sₚ], test_hist_edges[1])
raster_hist_we = RasterLayerHistogram(rs_stack[:Sₚ], test_hist_weights, test_hist_edges[1])
RLH = (raster_hist, raster_hist_nb, raster_hist_w, raster_hist_wnb,
       raster_hist_e, raster_hist_we)
# fitted histograms
find_nm_rs = @. !ismissing(rs_stack[:Sₚ])
find_nm_rs_vec = reshape(find_nm_rs, :)
raster_array_hist = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :))))
raster_array_hist_nb = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :)));
                           nbins = test_nbins)
raster_array_hist_w = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :))),
                          test_hist_weights[find_nm_rs_vec])
raster_array_hist_wnb = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :))),
                            test_hist_weights[find_nm_rs_vec]; nbins = test_nbins)
raster_array_hist_e = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :))),
                          test_hist_edges[1])
raster_array_hist_we = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :))),
                          test_hist_weights[find_nm_rs_vec], test_hist_edges[1] )
raster_array_hists = (raster_array_hist, raster_array_hist_nb, raster_array_hist_w,
                      raster_array_hist_wnb, raster_array_hist_e, raster_array_hist_we)

# `RasterStack`
stack_hist = RasterStackHistogram(rs_stack)
stack_hist_nb = RasterStackHistogram(rs_stack; nbins = test_nbins)
stack_hist_w = RasterStackHistogram(rs_stack, test_hist_weights)
stack_hist_wnb = RasterStackHistogram(rs_stack, test_hist_weights; nbins = test_nbins)
stack_hist_e = RasterStackHistogram(rs_stack, test_hist_edges)
stack_hist_we = RasterStackHistogram(rs_stack, test_hist_weights, test_hist_edges)
RSH = (stack_hist, stack_hist_nb, stack_hist_w, stack_hist_wnb, stack_hist_e, stack_hist_we)

find_nm_stack = @. !ismissing(rs_stack[:Sₚ]) && !ismissing(rs_stack[:θ])
find_nm_stack_vec = reshape(find_nm_stack, :)
Sₚ_vec = collect(skipmissing(rs_stack[:Sₚ][find_nm_stack]))
θ_vec = collect(skipmissing(rs_stack[:θ][find_nm_stack]))
stack_array_hist = fit(Histogram, (Sₚ_vec, θ_vec))
stack_array_hist_nb = fit(Histogram, (Sₚ_vec, θ_vec); nbins = test_nbins)
stack_array_hist_w = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_weights[find_nm_stack_vec])
stack_array_hist_wnb = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_weights[find_nm_stack_vec];
                           nbins = test_nbins)
stack_array_hist_e = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_edges)
stack_array_hist_we = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_weights[find_nm_stack_vec],
                          test_hist_edges)
stack_array_hists = (stack_array_hist, stack_array_hist_nb, stack_array_hist_w,
                     stack_array_hist_wnb, stack_array_hist_e, stack_array_hist_we)

# `RasterSeries`
test_hist_weights_series = randn(size(rs_series[1]))
series_hist_e = RasterSeriesHistogram(rs_series, test_hist_edges)
series_hist_we = RasterSeriesHistogram(rs_series, weights(test_hist_weights_series), test_hist_edges)
RSEH = (series_hist_e, series_hist_we)
# extract all data and compare `rs_hist` to `Histogram` from an `NTuple` of `Array`s
Sₚ_vec = Float64[]
θ_vec = Float64[]
test_series_weights = Float64[]
for r ∈ rs_series
    find_nm = @. !ismissing(r[:Sₚ]) && !ismissing(r[:θ])
    append!(test_series_weights, test_hist_weights_series[reshape(find_nm, :)])
    append!(Sₚ_vec, collect(skipmissing(r[:Sₚ][find_nm])))
    append!(θ_vec, collect(skipmissing(r[:θ][find_nm])))
end
series_array_hist_e = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_edges)
series_array_hist_we = fit(Histogram, (Sₚ_vec, θ_vec), weights(test_series_weights),
                           test_hist_edges)
series_array_hists = (series_array_hist_e, series_array_hist_we)

hist_fields = (:closed, :edges, :isdensity, :weights)
modes = (:none, :pdf, :probability, :density)

# Weight functions

lo, la, z, ti = lookup(rs_stack, X), lookup(rs_stack, Y), lookup(rs_stack, Z), lookup(rs_stack, Ti)
dx = (111e3 * (lo[2] - lo[1])) .* ones(length(lo))
dy = (111e3 * (la[2] - la[1])) .* cos.(deg2rad.(la))
dz = fill(abs(z[2]-z[1]), length(z))
# XY area
dA_XY = repeat(reshape(dx .* dy', :), outer = length(ti))
# XZ area
dA_XZ = repeat(reshape(dx .* dz', :), outer = length(ti))
# YZ area
dA_YZ = repeat(reshape(dy .* dz', :), outer = length(ti))
# Volume
dV = repeat(dz[1] * reshape(dx .* dy', :), outer = length(z) * length(ti))

## New method
# using OceanRasterConversions.RasterHistograms
# RasterLayerHistogram(rs_stack[:Sₚ])
# test = RasterStackHistogram(rs_stack)
# test = RasterSeriesHistogram(rs_series, (33:0.01:38, -2:0.1:20))
normalize(raster_array_hists[1]; mode = :none).weights
