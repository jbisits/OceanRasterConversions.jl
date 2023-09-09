var documenterSearchIndex = {"docs":
[{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"EditURL = \"https://github.com/jbisits/OceanRasterConversions.jl/blob/main/examples/ECCO_example.jl\"","category":"page"},{"location":"literated/ECCO_example/#Converting-the-practical-salinity-and-potential-temperature-from-ECCOv4r4-model-output.","page":"ECCO model output","title":"Converting the practical salinity and potential temperature from ECCOv4r4 model output.","text":"","category":"section"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"First, add the required dependencies","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"using OceanRasterConversions, Rasters, Plots, Downloads","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"and download model output from ECCOv4r4. This data is the daily average 0.5 degree salinity and temperature model output. To reproduce this example, an Earthdata acount is needed to download the data.","category":"page"},{"location":"literated/ECCO_example/#Read-the-data-into-a-RasterStack","page":"ECCO model output","title":"Read the data into a RasterStack","text":"","category":"section"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"Downloads.download(\"https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/ECCO%2520Ocean%2520Temperature%2520and%2520Salinity%2520-%2520Daily%2520Mean%25200.5%2520Degree%2520(Version%25204%2520Release%25204)/granules/OCEAN_TEMPERATURE_SALINITY_day_mean_2007-01-01_ECCO_V4r4_latlon_0p50deg.dap.nc4\", \"ECCO_data.nc\")\n\nstack = RasterStack(\"ECCO_data.nc\")","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"Thanks to Rasters.jl we now have the dimensions of the data, the variables saved as layers and all the metadata in one data structure. From the metadata we can get a summary of the data which tells us more about the data","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"metadata(stack)[\"summary\"]","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"This tells us that the temperature variable is potential temperature and the salt variabile is practical salinity (for more information about this data see the user guide).","category":"page"},{"location":"literated/ECCO_example/#Converting-variables-and-plotting","page":"ECCO model output","title":"Converting variables and plotting","text":"","category":"section"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"To calculate seawater density using TEOS-10, we require absolute salinity and conservative temperature. This can be done by extracting the data and using GibbsSeaWater.jl or with this package,","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"converted_stack = convert_ocean_vars(stack, (Sₚ = :SALT, θ = :THETA))","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"Note that this is a new RasterStack, so the metadata from the original RasterStack is not attached. As we have a returned RasterStack and plotting recipes have been written, we can then take slices of the data to look at depth-latitude plots of the returned variables (note by defaul the in-situ density ρ is computed and returned)","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"lon = 180\nvar_plots = plot(; layout = (4, 1), size = (900, 1000))\nfor (i, key) ∈ enumerate(keys(converted_stack))\n    contourf!(var_plots[i], converted_stack[key][X(Near(lon))])\nend\nvar_plots","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"As this is a RasterStack all methods exported by Rasters.jl will work. See the documentation for Rasters.jl for more information.","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"","category":"page"},{"location":"literated/ECCO_example/","page":"ECCO model output","title":"ECCO model output","text":"This page was generated using Literate.jl.","category":"page"},{"location":"#OceanRasterConversions.jl-documentation","page":"Home","title":"OceanRasterConversions.jl documentation","text":"","category":"section"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package converts ocean varaibles that are saved as Raster data structures using GibbsSeaWater.jl. Rasters.jl provides excellent reading, writing and manipulation of geospatial data. Typically, the salt and temperature variables from ocean models or observational data are practical salinity and potential temperature so conversions must be to the TEOS-10 standard variables of absolute salinity and conservative temperature to accurately calculate further variables like seawater density.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Further conversions and other water mass transformation procedures will be added in the future.","category":"page"},{"location":"#Package-workings","page":"Home","title":"Package workings","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package will convert the variables practical salinity and potential temperature into absolute salinity and conservative temperature. In doing so a pressure variable is needed, so this is created and returned in the RasterStack. Lastly a density variable (either in-situ or potential referenced to a user input) is computed and added to the RasterStack. See the example for how the package can be used.","category":"page"},{"location":"#Variables","page":"Home","title":"Variables","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The variables are named using the symbols that represent them. The symbols are unicode characters which can be generated in the julia repl by pressing tab after the varible","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> \\theta#press tab","category":"page"},{"location":"","page":"Home","title":"Home","text":"will autocomplete to θ, the symbol for potential temperature. The subscript letters that are used to distinguish between practical salinity, Sₚ, and absolute salinity, Sₐ, are also added in the julia repl","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> S\\_a#press tab","category":"page"},{"location":"","page":"Home","title":"Home","text":"Currently the varabile symbols are:","category":"page"},{"location":"","page":"Home","title":"Home","text":"θ potential temperature\nΘ conservative temperature\nSₚ practical salinity\nSₐ absolute salinity\np pressure\nρ in-situ seawater density\nσₚ potential density at user defined reference pressure ₚ.","category":"page"},{"location":"#Limitations","page":"Home","title":"Limitations","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"If the required dimensions for the conversions are not present an error will be thrown. For example, trying to convert a RasterStack that has no depth dimension will not work as the Z dimension is not found and the pressure variable depends on depth. There is a manual workaround for this. When defining the RasterStack add the Z dimension as a single entry, rather than a Vector,","category":"page"},{"location":"","page":"Home","title":"Home","text":"lons, lats, z = -180:180, -90:90, 0.0\nstack = RasterStack(data, (X(lons), Y(lats), Z(z)))","category":"page"},{"location":"","page":"Home","title":"Home","text":"This is equivalent to a two dimensional RasterStack at sea-surface height (z = 0).","category":"page"},{"location":"","page":"Home","title":"Home","text":"Currently the only dimension names that are supported are X, Y, Z, and Ti. Allowing for user specified dimensions has not yet been implemented.","category":"page"},{"location":"#Functions-exported-from-OceanRasterConversions","page":"Home","title":"Functions exported from OceanRasterConversions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"convert_ocean_vars\ndepth_to_pressure\nSₚ_to_Sₐ\nθ_to_Θ\nget_ρ\nget_σₚ","category":"page"},{"location":"#OceanRasterConversions.convert_ocean_vars","page":"Home","title":"OceanRasterConversions.convert_ocean_vars","text":"function convert_ocean_vars(raster::RasterStack, var_names::NamedTuple;\n                            ref_pressure = nothing,\n                            with_α = false,\n                            with_β = false)\nfunction convert_ocean_vars(raster::Rasterseries, var_names::NamedTuple;\n                            ref_pressure = nothing,\n                            with_α = false,\n                            with_β = false)\n\nConvert ocean variables depth, practical salinity and potential temperature to pressure, absolute salinity and conservative temperature. All conversions are done using the julia implementation of TEOS-10 GibbsSeaWater.jl. A new Raster is returned that contains the variables pressure, absolute salinity, conservative temperature and density (either in-situ or referenced to a user defined reference pressure). As pressure depends on latitude and depth, it is added as a new variable –- that is, each longitude, latitude, depth and time have a variable for pressure. A density variable is also computed which, by default, is in-situ density. Potential density at a reference pressure can be computed instead by passing a the keyword argument ref_pressure. Optional keyword arguments with_α and with_β allow the thermal expansion and haline contraction coefficients (respectively) to be computed and added to the returned RasterStack/Series.\n\nThe name of the variables for potential temperature and practical salinity must be passed in as a NamedTuple of the form (Sₚ = :salt_name, θ = :potential_temp_name) where :potential_temp_name and :salt_name are the name of the potential temperature and practical salinity in the Raster.\n\n\n\n\n\n","category":"function"},{"location":"#OceanRasterConversions.depth_to_pressure","page":"Home","title":"OceanRasterConversions.depth_to_pressure","text":"function depth_to_pressure(raster::Raster)\nfunction depth_to_pressure(stack::RasterStack)\n\nConvert the depth dimension (Z) to pressure using gsw_p_from_z  from GibbsSeaWater.jl. Note that pressure depends on depth and latitude so the returned pressure is stored as a variable in the resulting Raster rather than replacing the vertical depth dimension.\n\n\n\n\n\n","category":"function"},{"location":"#OceanRasterConversions.Sₚ_to_Sₐ","page":"Home","title":"OceanRasterConversions.Sₚ_to_Sₐ","text":"function Sₚ_to_Sₐ(Sₚ::Raster)\nfunction Sₚ_to_Sₐ(stack::RasterStack, Sₚ::Symbol)\nfunction Sₚ_to_Sₐ(series::RasterSeries, Sₚ::Symbol)\n\nConvert a Raster of practical salinity (Sₚ) to absolute salinity (Sₐ) using gsw_sa_from_sp from GibbsSeaWater.jl. This conversion depends on pressure. If converting from a RasterStack or RasterSeries, the symbol for the practical salinity in the RasterStack/Series must be passed in as a Symbol –-  that is if the variable name is SALT the RasterStack/Series, the Symbol :SALT must be passed in.\n\n\n\n\n\n","category":"function"},{"location":"#OceanRasterConversions.θ_to_Θ","page":"Home","title":"OceanRasterConversions.θ_to_Θ","text":"function θ_to_Θ(θ::Raster, Sₐ::Raster)\nfunction θ_to_Θ(stack::RasterStack, var_names::NamedTuple)\nfunction θ_to_Θ(series::RasterSeries, var_names::NamedTuple)\n\nConvert a Raster of potential temperature (θ) to conservative temperature (Θ) using gsw_ct_from_pt  from GibbsSeaWater.jl. This conversion depends on absolute salinity. If converting from a  from a RasterStack or a RasterSeries, the var_names must be passed in as for convert_ocean_vars –-  that is, as a named tuple in the form (Sₚ = :salt_name, θ = :potential_temp_name) where :potential_temp_name and :salt_name are the name of the potential temperature and salinity in the RasterStack.\n\n\n\n\n\n","category":"function"},{"location":"#OceanRasterConversions.get_ρ","page":"Home","title":"OceanRasterConversions.get_ρ","text":"function get_ρ(Sₐ::Raster, Θ::Raster, p::Raster)\nfunction get_ρ(stack::RasterStack, var_names::NamedTuple)\nfunction get_ρ(series::RasterStack, var_names::NamedTuple)\n\nCompute in-situ density, ρ, using gsw_rho from GibbsSeaWater.jl. This computation depends on absolute salinity (Sₐ), conservative temperature (Θ) and pressure (p). To compute ρ from a RasterStack or RasterSeries the variable names must be passed into the function as a NamedTuple in the form (Sₐ = :salt_var, Θ = :temp_var, p = :pressure_var). The returned Raster will have the same dimensions as Rasterstack that is passed in.\n\n\n\n\n\n","category":"function"},{"location":"#OceanRasterConversions.get_σₚ","page":"Home","title":"OceanRasterConversions.get_σₚ","text":"function get_σₚ(Sₐ::Raster, Θ::Raster, p::Float64)\nfunction get_σₚ(stack::RasterStack, var_names::NamedTuple)\nfunction get_σₚ(series::RasterStack, var_names::NamedTuple)\n\nCompute potential density at reference pressure p, σₚ, using gsw_rho from GibbsSeaWater.jl. This computation depends on absolute salinity (Sₐ), conservative temperature (Θ) and a user entered reference pressure (p). Compute and return the potential density σₚ at reference pressure p from a RasterStack or RasterSeries. This computation depends on absolute salinity Sₐ, conservative temperature Θ and a reference pressure p. The variable names must be passed into the function as a NamedTuple in the form (Sₐ = :salt_var, Θ = :temp_var, p = ref_pressure). Note p in this case is a number. The returned Raster will have the same dimensions as Rasterstack that is passed in.\n\n\n\n\n\n","category":"function"}]
}
