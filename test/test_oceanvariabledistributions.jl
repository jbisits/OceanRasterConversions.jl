# Single `Raster`
raster_hist = fit(Histogram, rs_stack[:Sₚ])
raster_array_hist = fit(Histogram, collect(skipmissing(reshape(rs_stack[:Sₚ], :))))

# `RasterStack`
stack_hist = fit(Histogram, rs_stack, (:Sₚ, :θ))
find_nm_stack = @. !ismissing(rs_stack[:Sₚ]) && !ismissing(rs_stack[:θ])
Sₚ_vec = collect(skipmissing(rs_stack[:Sₚ][find_nm_stack]))
θ_vec = collect(skipmissing(rs_stack[:θ][find_nm_stack]))
stack_array_hist = fit(Histogram, (Sₚ_vec, θ_vec))

# `RasterSeries`
test_hist_bins = (33:0.025:38, -2:0.1:20)
series_hist = fit(Histogram, rs_series, (:Sₚ, :θ), test_hist_bins)

# extract all data and compare `rs_hist` to `Histogram` from an `NTuple` of `Array`s
Sₚ_vec = Float64[]
θ_vec = Float64[]
for r ∈ rs_series
    find_nm = @. !ismissing(r[:Sₚ]) && !ismissing(r[:θ])
    append!(Sₚ_vec, collect(skipmissing(r[:Sₚ][find_nm])))
    append!(θ_vec, collect(skipmissing(r[:θ][find_nm])))
end

series_array_hist = fit(Histogram, (Sₚ_vec, θ_vec), test_hist_bins)

hist_fields = (:closed, :edges, :isdensity, :weights)

# Weight functions

test_weights_single = randn(length(reshape(rs_stack[:Sₚ], :)))
single_var_weights = single_variable_weights(rs_stack[:Sₚ], test_weights_single)
find_nm_rs_stack = @. !ismissing(rs_stack[:Sₚ])
find_nm_xy = reshape(find_nm_rs_stack[Z(1)], :)
find_nm_xz = reshape(find_nm_rs_stack[Y(1)], :)
find_nm_yz = reshape(find_nm_rs_stack[X(1)], :)
find_nm_rs_stack = reshape(find_nm_rs_stack, :)

lo, la, z, ti = lookup(rs_stack, X), lookup(rs_stack, Y), lookup(rs_stack, Z), lookup(rs_stack, Ti)
dx = (111e3 * (lo[2] - lo[1])) .* ones(length(lo))
dy = (111e3 * (la[2] - la[1])) .* cos.(deg2rad.(la))
dz = fill(abs(z[2]-z[1]), length(z))
# XY area
dA_xy = repeat(reshape(dx .* dy', :), outer = length(ti))
dA_xy_test = dA_xy[find_nm_xy]
# XZ area
dA_xz = repeat(reshape(dx .* dz', :), outer = length(ti))
dA_xz_test = dA_xz[find_nm_xz]
# YZ area
dA_yz = repeat(reshape(dy .* dz', :), outer = length(ti))
dA_yz_test = dA_yz[find_nm_yz]
# Volume
dV = repeat(dz[1] * reshape(dx .* dy', :), outer = length(z) * length(ti))
dV_test = dV[find_nm_rs_stack]
