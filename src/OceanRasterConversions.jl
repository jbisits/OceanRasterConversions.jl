module OceanRasterConversions

using Rasters, GibbsSeaWater

export
    convert_ocean_vars,
    depth_to_pressure, Sₚ_to_Sₐ, θ_to_Θ,
    in_situ_density, potential_density

include("oceanconversions.jl")

end #module
