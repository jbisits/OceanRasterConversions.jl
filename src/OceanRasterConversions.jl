"""
Module to convert variables depth, practical salinity and potential temperature to the
TEOS-10 standard variables pressure, absolute salinity and conservative temperature
(respectively) from a `Raster`, `RasterStack`  or `RasterSeries`. A few chosen seawater
variables can then be computed from these state variables.
"""
module OceanVariableConversions

include("oceanvariableconversions.jl")

end #module
