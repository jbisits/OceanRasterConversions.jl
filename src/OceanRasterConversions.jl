module OceanRasterConversions

using Rasters, GibbsSeaWater

export
    convert_ocean_vars,
    depth_to_pressure, Sₚ_to_Sₐ, θ_to_Θ,
    get_ρ, get_σₚ, get_α, get_β

include("oceanconversions.jl")

end #module
