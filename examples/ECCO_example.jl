# # Converting the practical salinity and potential temperature from ECCOv4r4 model output.
# First, add the required dependencies
using OceanRasterConversions, Rasters, Plots, Downloads
# and download model output from [ECCOv4r4](https://ecco-group.org/products-ECCO-V4r4.htm).
# This data is the daily average 0.5 degree salinity and temperature model output. To reproduce
# this example, an Earthdata acount is needed to download the data.
# ## Read the data into a `RasterStack`
Downloads.download("https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/ECCO%2520Ocean%2520Temperature%2520and%2520Salinity%2520-%2520Daily%2520Mean%25200.5%2520Degree%2520(Version%25204%2520Release%25204)/granules/OCEAN_TEMPERATURE_SALINITY_day_mean_2007-01-01_ECCO_V4r4_latlon_0p50deg.dap.nc4", "ECCO_data.nc")

stack = RasterStack("ECCO_data.nc")
# Thanks to [Rasters.jl](https://github.com/rafaqz/Rasters.jl) we now have the dimensions of
# the data, the variables saved as layers and all the metadata in one data structure.
# From the metadata we can get a summary of the data which tells us more about the data
metadata(stack)["summary"]

# This tells us that the temperature variable is potential temperature and the salt
# variabile is practical salinity (for more information about this data see the user guide).
#
# ## Converting all variables and plotting
# To calculate seawater density using TEOS-10, we require absolute salinity, conservative
# temperature and pressure. This can be done by extracting the data and using
# [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl) or with this package,
converted_stack = convert_ocean_vars(stack, (Sₚ = :SALT, θ = :THETA))

# Note that this is a new `RasterStack`, so the metadata from the original `RasterStack` is
# not attached. As we have a returned `RasterStack` and plotting recipes have been written,
# we can, for example, look at the conservative temperature closest to the sea-surface (-5.0m)
contourf(converted_stack[:Θ][Z(Near(0.0))]; size = (800, 800),
         color = :balance, colorbar_title = "ᵒC")

# We can also take slices of the data to look at depth-latitude plots of the returned
# variables (note by default the in-situ density `ρ` is computed and returned)
lon = 180
var_plots = plot(; layout = (4, 1), size = (1000, 1000))
for (i, key) ∈ enumerate(keys(converted_stack))
    contourf!(var_plots[i], converted_stack[key][X(Near(lon))])
end
var_plots
# As this is a `RasterStack` all methods exported by Rasters.jl will work. See the
# [documentation for Rasters.jl](https://rafaqz.github.io/Rasters.jl/stable/#Rasters.jl)
# for more information.

# ## Converting chosen variables
# It is also possible to convert only chosen variables from a `RasterStack`. If we just want
# to look at temperature-salinity vertical profiles, we can convert the practical salinity
# and conservative temperature then extact vertical profiles and compute the potential
# density referenced to 0dbar
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
