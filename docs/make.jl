using Documenter, Literate, OceanRasterConversions, DocumenterCitations
const EXAMPLES_DIR = joinpath(@__DIR__, "../examples")
const OUTPUT_DIR   = joinpath(@__DIR__, "src/literated")

to_be_literated = EXAMPLES_DIR .*"/".* readdir(EXAMPLES_DIR)

for file ∈ to_be_literated
    Literate.markdown(file, OUTPUT_DIR)
    Literate.script(file, OUTPUT_DIR)
end

example_pages = [
   "Converting ocean variables" => "literated/ocean_variable_conversion.md",
]
module_pages = [
    "OceanVariableConversions" => "modules/OceanVariableConversions.md",
]
library_pages = [
    "Function index" => "library/function_index.md"
]
pages = [
    "Home" => "index.md",
    "Modules" => module_pages,
    "Examples" => example_pages,
    "Library" => library_pages
]

bib = CitationBibliography(joinpath(@__DIR__, "src/refs.bib"))

makedocs(bib,
        modules = [OceanRasterConversions],
        sitename = "OceanRasterConversions.jl",
        repo="https://github.com/jbisits/OceanRasterConversions.jl/blob/{commit}{path}#{line}",
        doctest = true,
        authors="Josef Bisits <jbisits@gmail.com>",
        format=Documenter.HTML(;
            prettyurls=get(ENV, "CI", "false") == "true",
            canonical="https://jbisits.github.io/OceanRasterConversions.jl",
            edit_link="main",
            assets=String[],
        ),
        pages = pages
        )

deploydocs(
        repo = "github.com/jbisits/OceanRasterConversions.jl.git",
        versions = ["stable" => "v^", "v#.#.#", "dev" => "dev"],
        push_preview = false,
        forcepush = true,
        devbranch = "main"
        )
