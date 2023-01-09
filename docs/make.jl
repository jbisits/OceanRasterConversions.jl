using Documenter, Rasters, GibbsSeaWater, Plots
using .OceanRasterConversions

makedocs(
    modules = [OceanRasterConversions],
    sitename = "OceanRasterConversions.jl",
    doctest = false,
    clean = true,
    author = "Josef I. Bisits"
)

deploydocs(repo = "github.com/jbisits/OceanRasterConversions.jl.git")
