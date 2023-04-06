module OceanRasterConversions

using Rasters, GibbsSeaWater, StatsBase
import StatsBase.fit

export
    convert_ocean_vars,
    depth_to_pressure, Sₚ_to_Sₐ, θ_to_Θ,
    get_ρ, get_σₚ, get_α, get_β

export area_weights, volume_weights

include("oceanconversions.jl")
include("oceanvariabledistributions.jl")

end #module
