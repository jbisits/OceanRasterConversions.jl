# # [Converting the practical salinity and potential temperature from ECCOv4r4 model output.](@id converting_variables_example)
# First, add the required dependencies
using Rasters, NCDatasets, Plots, Downloads
using OceanRasterConversions
# and download model output from [ECCOv4r4](https://ecco-group.org/products-ECCO-V4r4.htm)
# [Fukumori2022](@cite), [Fukumori2021](@cite), [Forget2015](@cite).
# This data is the daily average 0.5 degree salinity and temperature model output. To reproduce
# this example, an Earthdata acount is needed to download the data.
# !!! info
#     See the [NCDatasets.jl example](https://alexander-barth.github.io/NCDatasets.jl/latest/tutorials/#Data-from-NASA-EarthData)
#     for information on how to download data from NASA EarthData.
# ## Read the data into a `RasterStack`
function download_ECCO()

    try
        Downloads.download("https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/ECCO%2520Ocean%2520Temperature%2520and%2520Salinity%2520-%2520Daily%2520Mean%25200.5%2520Degree%2520(Version%25204%2520Release%25204)/granules/OCEAN_TEMPERATURE_SALINITY_day_mean_2007-01-01_ECCO_V4r4_latlon_0p50deg.dap.nc4", "ECCO_data.nc")
    catch
        @info "dowloading from drive"
        Downloads.download("https://drive.google.com/uc?id=1MNeThunqpY-nFzsZLZj9BV8sM5BJgnxT&export=download", "ECCO_data.nc")
    end

    return nothing

end
download_ECCO()
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
contourf(converted_stack[:Θ][Z(Near(0.0)), Ti(1)]; size = (800, 500),
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
# to look at conservative temperature - absolute salinity vertical profiles, we can convert
# the practical salinity and potential temperature then extract vertical profiles
# and compute the potential density referenced to 0dbar
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

# ## Plotting with [GeoMakie.jl](https://github.com/MakieOrg/GeoMakie.jl)
# Rasters.jl also
# [supports plotting with Makie.jl](https://rafaqz.github.io/Rasters.jl/dev/#Plotting-in-Makie)
# as of version 0.5.3.
# If using an older version we can write a method
# for `convert_arguments` to convert a `Raster` into a format that can be plotted by
# Makie.jl. For more information on implementing type recipes for plotting custom types in
# Makie.jl see the
# [Makie.jl plot recipes documentation](https://docs.makie.org/stable/documentation/recipes/).
# The `convert_arguments` method extracts the longitude and latitude `dims` from a `Raster`
# as well as the values for the chosen variable. The `SurfaceLike` argument converts the
# data so we can use the `contourf`, `heatmap` or other `SurfaceLike` plotting functions.
using GeoMakie, CairoMakie

function Makie.convert_arguments(P::SurfaceLike, rs::Raster)

    lon, lat = collect(lookup(rs, X)), collect(lookup(rs, Y))
    plot_var = Matrix(rs[:, :])

    return convert_arguments(P, lon, lat, plot_var)

end
# !!! info "convert_arguments method"
#     This is a specific method for `convert_arguments` written for this data. To plot
#     different data (or other parts of this data, e.g. depth-latitude) that are in `Raster`
#     data structures, more methods need to be added to `convert_arguments` that extract the
#     desired parts of the `Raster`.
# Now we can plot a `Raster` onto a `GeoAxis` and take advantage of the extra features
# GeoMakie.jl offers, like map projections
# (see the [GeoMakie.jl documentation](https://geo.makie.org/stable/#Map-projections) for more
# information about available projections and how to set them), automatic axis limits and
# coastlines.
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
# ```@bibliography
# ```
