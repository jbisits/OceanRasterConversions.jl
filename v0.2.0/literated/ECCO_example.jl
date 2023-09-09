using OceanRasterConversions, Rasters, Plots, Downloads

Downloads.download("https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/ECCO%2520Ocean%2520Temperature%2520and%2520Salinity%2520-%2520Daily%2520Mean%25200.5%2520Degree%2520(Version%25204%2520Release%25204)/granules/OCEAN_TEMPERATURE_SALINITY_day_mean_2007-01-01_ECCO_V4r4_latlon_0p50deg.dap.nc4", "ECCO_data.nc")

stack = RasterStack("ECCO_data.nc")

metadata(stack)["summary"]

converted_stack = convert_ocean_vars(stack, (Sₚ = :SALT, θ = :THETA))

lon = 180
var_plots = plot(; layout = (4, 1), size = (900, 1000))
for (i, key) ∈ enumerate(keys(converted_stack))
    contourf!(var_plots[i], converted_stack[key][X(Near(lon))])
end
var_plots

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

