using Rasters, NCDatasets, Plots, Downloads
using OceanRasterConversions

Downloads.download("https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/ECCO%2520Ocean%2520Temperature%2520and%2520Salinity%2520-%2520Daily%2520Mean%25200.5%2520Degree%2520(Version%25204%2520Release%25204)/granules/OCEAN_TEMPERATURE_SALINITY_day_mean_2007-01-01_ECCO_V4r4_latlon_0p50deg.dap.nc4", "ECCO_data.nc")

stack = RasterStack("ECCO_data.nc")

metadata(stack)["summary"]

converted_stack = convert_ocean_vars(stack, (Sₚ = :SALT, θ = :THETA))

contourf(converted_stack[:Θ][Z(Near(0.0)), Ti(1)]; size = (800, 500),
         color = :balance, colorbar_title = "ᵒC")

lon = 180
var_plots = plot(; layout = (4, 1), size = (1000, 1000))
for (i, key) ∈ enumerate(keys(converted_stack))
    contourf!(var_plots[i], converted_stack[key][X(Near(lon))])
end
var_plots

Sₐ = Sₚ_to_Sₐ(stack, :SALT)
Θ = θ_to_Θ(stack, (Sₚ = :SALT, θ = :THETA))
lon, lat = -100.0, -70.0
Sₐ_profile, Θ_profile = Sₐ[X(Near(lon)), Y(Near(lat)), Ti(1)],
                         Θ[X(Near(lon)), Y(Near(lat)), Ti(1)]
σ₀_profile = get_σₚ(Sₐ_profile, Θ_profile, 0)
profile_plots = plot(; layout = (2, 2), size = (800, 800))
plot!(profile_plots[1, 1], Sₐ_profile;
      title = "Sₐ-depth", xmirror = true, xlabel = "Sₐ (g/kg)")
plot!(profile_plots[1, 2], Θ_profile;
      title = "Θ-depth", xmirror = true, xlabel = "Θ (ᵒC)")
plot!(profile_plots[2, 1], Sₐ_profile, Θ_profile;
      xlabel = "Sₐ (g/kg)", ylabel = "Θ (ᵒC)", label = false, title = "Sₐ-Θ")
plot!(profile_plots[2, 2], σ₀_profile;
      title = "σ₀-depth", xmirror = true, xlabel = "σ₀ (kgm⁻³)")

using GeoMakie, CairoMakie

function Makie.convert_arguments(P::SurfaceLike, rs::Raster)

    lon, lat = collect(lookup(rs, X)), collect(lookup(rs, Y))
    plot_var = Matrix(rs[:, :])

    return convert_arguments(P, lon, lat, plot_var)

end

date = lookup(converted_stack, Ti)[1] # get the date from the `Raster`
depth = 0.0                           # choose a depth to look at the ocean temperature
fig = Figure(size = (800, 500))
ax = GeoAxis(fig[1, 1];
             xlabel = "Longitude",
             ylabel = "Latitude",
             title = "Ocean conservative temperature at depth $(depth)m",
             subtitle = "$date",
             coastlines = true)
cp = CairoMakie.contourf!(ax, converted_stack[:Θ][Z(Near(depth)), Ti(At(date))];
                          colormap = :balance)
Colorbar(fig[2, 1], cp; label = "Θ (ᵒC)", vertical = false, flipaxis = false)
fig

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
