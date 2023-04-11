module OceanRasterConversions

using Reexport, DocStringExtensions

include("oceanvariableconversions.jl")
include("oceanvariabledistributions.jl")

@reexport using OceanRasterConversions.OceanVariableConversions
@reexport using OceanRasterConversions.RasterHistograms

end #module
