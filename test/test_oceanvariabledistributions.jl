# I think I can test nearly all my `fit` methods with a `RasterSeries`

test_hist_bins = (33:0.025:38, -2:0.1:20)
raster_hist = fit(Histogram, rs_series, (:Sₚ, :θ), test_hist_bins)

# extract all data and compare `rs_hist` to `Histogram` from an `NTuple` of `Array`s
Sₚ_vec = Float64[]
θ_vec = Float64[]
for r ∈ rs_series
    find_nm = @. !ismissing(r[:Sₚ]) && !ismissing(r[:θ])
    append!(Sₚ_vec, collect(skipmissing(r[:Sₚ][find_nm])))
    append!(θ_vec, collect(skipmissing(r[:θ][find_nm])))
end

array_hist = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_bins)

hist_fields = (:closed, :edges, :isdensity, :weights)
