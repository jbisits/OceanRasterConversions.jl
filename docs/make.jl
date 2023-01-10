using Documenter, Literate, Rasters, GibbsSeaWater, Plots
const MODULE_DIR = normpath(joinpath(@__DIR__, "../src/OceanRasterConversions.jl"))
include(MODULE_DIR)
using .OceanRasterConversions

const EXAMPLES_DIR = joinpath(@__DIR__, "../examples")
const OUTPUT_DIR   = joinpath(@__DIR__, "src/literated")

example_filepath = normpath(joinpath(EXAMPLES_DIR, "ECCO_example.jl"))
Literate.markdown(example_filepath, OUTPUT_DIR)
Literate.script(example_filepath, OUTPUT_DIR)

makedocs(
        modules = [OceanRasterConversions],
        sitename = "OceanRasterConversions.jl",
        doctest = false,
        clean = true,
        authors = "Josef I. Bisits",
        pages = Any["Home" => "index.md",
                    "Examples" => Any["ECCO model output" => "literated/ECCO_example.md"]
                    ]
        )

deploydocs(
        repo = "github.com/jbisits/OceanRasterConversions.jl.git",
        versions = ["stable" => "v^", "v#.#.#", "dev" => "dev"],
        push_preview = false,
        forcepush = true,
        devbranch = "main"
        )
