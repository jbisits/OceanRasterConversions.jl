# ### Converting the practical salinity and potential temperature from ECCOv4r4 model
# output.
# First, add the required dependencies
using Rasters, GibbsSeaWater, Plots, Downloads
include("/Users/Joey/Documents/GitHub/OceanRasterConversions.jl/src/OceanRasterConversions.jl")
using .OceanRasterConversions
# and download model output from ECCOv4r4 (note this needs an Earthdata account).
# This data is the daily average 0.5 degree output of salinity and temperature. To reproduce
# this example, an Earthdata acount is needed to download the data insert link.
# ### Read the data into a `RasterStack`
Downloads.download("https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/ECCO%2520Ocean%2520Temperature%2520and%2520Salinity%2520-%2520Daily%2520Mean%25200.5%2520Degree%2520(Version%25204%2520Release%25204)/granules/OCEAN_TEMPERATURE_SALINITY_day_mean_2007-01-01_ECCO_V4r4_latlon_0p50deg.dap.nc4", "ECCO_data.nc")

stack = RasterStack("ECCO_data.nc")
# Thanks to [Rasters.jl](https://github.com/rafaqz/Rasters.jl) we now have the dimensions of
# the data, the variables saved as layers and all the metadata in one data structure.
# From the metadata we can get a summary of the data which tells us more about the data
metadata(stack)["summary"]

# This tells us that the temperature variable is potential temperature and the salt
# variabile is practical salinity (for more information about this data see the user guide).
#
# ### Converting variables
# To calculate seawater density using TEOS-10, we require absolute salinity and
# conservative temperature. This can be done by extracting the data and using
# [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl) or with this package,
converted_stack = convert_ocean_vars(stack, (sp = :SALT, pt = :THETA))

# Note that this is a new `RasterStack`, so the metadata from the original `RasterStack` is
# not attached. As we have a returned `RasterStack` and plotting recipes have been written,
# we can then take slices of the data to look at depth-latitude plots of the returned
# variables (note by defaul the in-situ density ρ is computed and returned)
lon = 180
var_plots = plot(; layout = (4, 1), size = (850, 1000))
for (i, key) ∈ enumerate(keys(converted_stack))
    contourf!(var_plots[i], converted_stack[key][X(Near(lon))])
end
var_plots
# As this is a `RasterStack` all methods exported by Rasters.jl will work. See the
# [documentation for Rasters.jl](https://rafaqz.github.io/Rasters.jl/stable/#Rasters.jl)
# for more information.
