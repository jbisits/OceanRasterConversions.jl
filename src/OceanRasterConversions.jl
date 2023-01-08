module OceanRasterConversions

using Rasters, GibbsSeaWater

export convert_ocean_vars, depth_to_pressure, Sₚ_to_Sₐ, θ_to_Θ

include("oceanconversions.jl")

end #module
