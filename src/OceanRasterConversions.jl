"""
Module to convert variables depth, practical salinity and potential temperature to the
TEOS-10 standard variables pressure, absolute salinity and conservative temperature
(respectively) from a `Raster`, `RasterStack`  or `RasterSeries`. A few chosen seawater
variables can then be computed from these state variables.
"""
module OceanRasterConversions

using Rasters, GibbsSeaWater, DocStringExtensions

export
    convert_ocean_vars,
    depth_to_pressure, Sₚ_to_Sₐ, θ_to_Θ,
    get_ρ, get_σₚ, get_α, get_β


include("oceanvariableconversions.jl")
include("z_to_p.jl")
include("sp_to_sa.jl")
include("theta_to_Theta.jl")
include("seawaterdensity.jl")
include("alphaandbeta.jl")

end #module
