## Generate random practical salinity and potential temperature data.
lons, lats, z, time = -180:4.0:180, -90:2.0:90, -0:-10.0:-2000, 1:2
rs_dims = (lons, lats, z, time)
N = 500
Sₚ_vals = vcat(range(33, 38, length = N), missing)
θ_vals = vcat(range(-2, 20, length = N), missing)
ref_pressure = 1000.0

## All dimensions
Sₚ = rand(Sₚ_vals, X(lons), Y(lats), Z(z), Ti(time))
θ = rand(θ_vals, X(lons), Y(lats), Z(z), Ti(time))
test_vars = (Sₚ = Sₚ, θ = θ)
rs_stack = RasterStack(test_vars, (X(lons), Y(lats), Z(z), Ti(time)))
rs_series = RasterSeries([rs_stack[Ti(t)] for t ∈ time], Ti)

## No `X` dim
Sₚ_noX = rand(Sₚ_vals, Y(lats), Z(z), Ti(time))
θ_noX = rand(θ_vals, Y(lats), Z(z), Ti(time))
test_vars_noX = (Sₚ = Sₚ_noX, θ = θ_noX)
rs_stack_NoX = RasterStack(test_vars_noX, (Y(lats), Z(z), Ti(time)))

## No `Y` dim
Sₚ_noY = rand(Sₚ_vals, X(lons), Z(z), Ti(time))
θ_noY = rand(θ_vals, X(lons), Z(z), Ti(time))
test_vars_noY = (Sₚ = Sₚ_noY, θ = θ_noY)
rs_stack_NoY = RasterStack(test_vars_noY, (X(lons), Z(z), Ti(time)))

## No `Z` dim
Sₚ_noZ = rand(Sₚ_vals, X(lons), Y(lats), Ti(time))
θ_noZ = rand(θ_vals, X(lons), Y(lats), Ti(time))
test_vars_noZ = (Sₚ = Sₚ_noZ, θ = θ_noZ)
rs_stack_NoZ = RasterStack(test_vars_noZ, (X(lons), Y(lats), Ti(time)))

## Output to test
converted_p = depth_to_pressure(rs_stack)
converted_Sₚ = Sₚ_to_Sₐ(rs_stack, :Sₚ)
converted_Sₚ_series = Rasters.combine(Sₚ_to_Sₐ(rs_series, :Sₚ), Ti)
converted_θ = θ_to_Θ(rs_stack, :θ, :Sₚ)
converted_θ_series = Rasters.combine(θ_to_Θ(rs_series, :θ, :Sₚ), Ti)
rs_stack_res_in_situ = convert_ocean_vars(rs_stack, (sp = :Sₚ, pt = :θ))
rs_stack_res_pd = convert_ocean_vars(rs_stack, (sp = :Sₚ, pt = :θ); ref_pressure)
rs_series_res_in_situ = convert_ocean_vars(rs_series, (sp = :Sₚ, pt = :θ))
rs_series_res_pd = convert_ocean_vars(rs_series, (sp = :Sₚ, pt = :θ); ref_pressure)

test_vars_in_situ = keys(rs_stack_res_in_situ)
test_vars_pd = keys(rs_stack_res_pd)

## Transform p, Sₚ and θ then find ρ (in-situ and potential) to test functions against
p = similar(Array(Sₚ))
Sₐ = similar(Array(Sₚ))
Θ = similar(Array(Sₚ))
ρ = similar(Array(Sₚ))
σₚ = similar(Array(Sₚ))
## Compare the standalone functions
Sₐ_ = similar(Array(Sₚ))
for t ∈ time
    for (i, lon) ∈ enumerate(lons), (j, lat) ∈ enumerate(lats)

        p[i, j, :, t] .= gsw_p_from_z.(z, lat)

        find_nm = findall(.!ismissing.(Sₚ[i, j, :, t]) .&& .!ismissing.(θ[i, j, :, t]))

        Sₐ[i, j, find_nm, t] .= gsw_sa_from_sp.(Sₚ[i, j, find_nm, t],
                                                p[i, j, find_nm, t], lon, lat)

        Θ[i, j, find_nm, t] .= gsw_ct_from_pt.(Sₐ[i, j, find_nm, t], θ[i, j, find_nm, t])

        ρ[i, j, find_nm, t] .= gsw_rho.(Sₐ[i, j, find_nm, t],
                                        Θ[i, j, find_nm, t],
                                        p[i, j, find_nm, t])

        σₚ[i, j, find_nm, t] .= gsw_rho.(Sₐ[i, j, find_nm, t],
                                         Θ[i, j, find_nm, t],
                                         ref_pressure)
        find_nm_salt = findall(.!ismissing.(Sₚ[i, j, :, t]))
        Sₐ_[i, j, find_nm_salt, t] .= gsw_sa_from_sp.(Sₚ[i, j, find_nm_salt, t],
                                                      p[i, j, find_nm_salt, t], lon, lat)
    end
end

vars_in_situ = (p, Sₐ, Θ, ρ)
vars_pd = (p, Sₐ, Θ, σₚ)
