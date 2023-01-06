## Generate random practical salinity and potential temperature data.
lons, lats, z, time = -180:4.0:180, -90:2.0:90, -0:-10.0:-2000, 1:2
rs_dims = (lons, lats, z, time)
N = 500
Sₚ_vals = vcat(range(33, 38, length = N), missing)
θ_vals = vcat(range(-2, 20, length = N), missing)
Sₚ = rand(Sₚ_vals, X(lons), Y(lats), Z(z), Ti(time))
θ = rand(θ_vals, X(lons), Y(lats), Z(z), Ti(time))
ref_pressure = 1000.0
test_vars = (Sₚ = Sₚ, θ = θ)
rs_stack = RasterStack(test_vars, (X(lons), Y(lats), Z(z), Ti(time)))
rs_series = RasterSeries([rs_stack[Ti(t)] for t ∈ time], Ti)

## Output to test
rs_stack_res_in_situ = convert_ocean_vars(rs_stack, (sp = :Sₚ, pt = :θ))
rs_stack_res_pd = convert_ocean_vars(rs_stack, (sp = :Sₚ, pt = :θ); ref_pressure)
rs_series_res_in_situ = convert_ocean_vars(rs_series, (sp = :Sₚ, pt = :θ))
rs_series_res_pd = convert_ocean_vars(rs_series, (sp = :Sₚ, pt = :θ); ref_pressure)

test_vars = keys(rs_stack_res_in_situ)

## Transform p, Sₚ and θ then find ρ (in-situ and potential) to test against
p = similar(Array(Sₚ))
Sₐ = similar(Array(Sₚ))
Θ = similar(Array(Sₚ))
ρ = similar(Array(Sₚ))
ρ_ref = similar(Array(Sₚ))
for t ∈ time
    for (i, lon) ∈ enumerate(lons), (j, lat) ∈ enumerate(lats)
        p[i, j, :, t] .= gsw_p_from_z.(z, lat)
        find_nm = findall(.!ismissing.(Sₚ[i, j, :, t]) .&& .!ismissing.(θ[i, j, :, t]))
        Sₐ[i, j, find_nm, t] .= gsw_sa_from_sp.(Sₚ[i, j, find_nm, t], p[i, j, find_nm, t], lon, lat)
        Θ[i, j, find_nm, t] .= gsw_ct_from_pt.(Sₐ[i, j, find_nm, t], θ[i, j, find_nm, t])
        ρ[i, j, find_nm, t] .= gsw_rho.(Sₐ[i, j, find_nm, t], Θ[i, j, find_nm, t], p[i, j, find_nm, t])
        ρ_ref[i, j, find_nm, t] .= gsw_rho.(Sₐ[i, j, find_nm, t], Θ[i, j, find_nm, t], ref_pressure)
    end
end

vars_in_situ = (p, Sₐ, Θ, ρ)
vars_pd = (p, Sₐ, Θ, ρ_ref)
