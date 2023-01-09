using Documenter, Literate, Rasters, GibbsSeaWater, Plots
using .OceanRasterConversions

const EXAMPLES_DIR = joinpath(@__DIR__, "../..", "examples")
const OUTPUT_DIR   = joinpath(@__DIR__, "src/literated")

example_filepath = joinpath(EXAMPLES_DIR, "ECCO_example.jl")
Literate.markdown(example_filepath, OUTPUT_DIR)
Literate.script(example_filepath, OUTPUT_DIR)

makedocs(
        modules = [OceanRasterConversions],
        sitename = "OceanRasterConversions.jl",
        doctest = false,
        clean = true,
        author = "Josef I. Bisits",
        pages = Any["Home" => "index.md",
                    "Examples" => "literated/ECCO_example.md"
                    ]
        )

deploydocs(
        repo = "github.com/jbisits/OceanRasterConversions.jl.git",
        versions = ["stable" => "v^", "v#.#.#", "dev" => "dev"],
        push_preview = false,
        forcepush = true,
        devbranch = "main"
        )
