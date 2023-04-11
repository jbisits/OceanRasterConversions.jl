using Documenter, Literate, OceanRasterConversions
const EXAMPLES_DIR = joinpath(@__DIR__, "../examples")
const OUTPUT_DIR   = joinpath(@__DIR__, "src/literated")

to_be_literated = EXAMPLES_DIR .*"/".* readdir(EXAMPLES_DIR)

for file ∈ to_be_literated
    Literate.markdown(file, OUTPUT_DIR)
    Literate.script(file, OUTPUT_DIR)
end

example_pages = [
   "Converting ocean variables" => "literated/ocean_variable_conversion.md",
   "Histograms from `Raster`s" => "literated/raster_histograms.md"
]
module_pages = [
    "OceanVariableConversions" => "modules/OceanVariableConversions.md",
    "RasterHistograms"         => "modules/RasterHistograms.md"
]
pages = [
    "Home" => "index.md",
    "Examples" => example_pages,
    "Modules" => module_pages
]

makedocs(
        modules = [OceanRasterConversions],
        sitename = "OceanRasterConversions.jl",
        doctest = true,
        clean = true,
        authors = "Josef I. Bisits",
        pages = pages
        )

deploydocs(
        repo = "github.com/jbisits/OceanRasterConversions.jl.git",
        versions = ["stable" => "v^", "v#.#.#", "dev" => "dev"],
        push_preview = false,
        forcepush = true,
        devbranch = "main"
        )
