"""
    function get_ρ(Sₐ::Raster, Θ::Raster, p::Raster)
    function get_ρ(stack::RasterStack, var_names::NamedTuple)
    function get_ρ(series::RasterStack, var_names::NamedTuple)
Compute in-situ density, `ρ`, using `gsw_rho` from GibbsSeaWater.jl. This computation
depends on absolute salinity (`Sₐ`), conservative temperature (`Θ`) and pressure (`p`).
To compute ρ from a `RasterStack` or `RasterSeries` the variable names must be passed into the
function as a `NamedTuple` in the form `(Sₐ = :salt_var, Θ = :temp_var, p = :pressure_var)`.
The returned `Raster` will have the same dimensions as `Rasterstack` that is passed in.
"""
function get_ρ(Sₐ::Raster, Θ::Raster, p::Raster, find_nm::Raster)

    ρ = similar(Array(Sₐ))
    @. ρ[find_nm] = GibbsSeaWater.gsw_rho(Sₐ[find_nm], Θ[find_nm], p[find_nm])

    return Raster(ρ, dims(Sₐ))

end
function get_ρ(Sₐ::Raster, Θ::Raster, p::Raster)

    Sₐ, Θ, p = read(Sₐ), read(Θ), read(p)
    find_nm = @. !ismissing(Sₐ) && !ismissing(Θ)

    return get_ρ(Sₐ, Θ, p, find_nm)

end
get_ρ(stack::RasterStack, var_names::NamedTuple) = get_ρ(stack[var_names.Sₐ],
                                                         stack[var_names.Θ],
                                                         stack[var_names.p])
get_ρ(series::RasterSeries, var_names::NamedTuple) = get_ρ.(series, Ref(var_names))

"""
    function get_σₚ(Sₐ::Raster, Θ::Raster, p::Number)
    function get_σₚ(stack::RasterStack, var_names::NamedTuple)
    function get_σₚ(series::RasterStack, var_names::NamedTuple)
Compute potential density at reference pressure `p`, `σₚ`, using `gsw_rho`
from GibbsSeaWater.jl. This computation depends on absolute salinity (`Sₐ`),
conservative temperature (`Θ`) and a user entered reference pressure (`p`).
Compute and return the potential density `σₚ` at reference pressure `p` from a
`RasterStack` or `RasterSeries`. This computation depends on absolute salinity `Sₐ`,
conservative temperature `Θ` and a reference pressure `p`. The variable names must be
passed into the function as a `NamedTuple` in the form
`(Sₐ = :salt_var, Θ = :temp_var, p = ref_pressure)`. Note `p` in this case is a number.
The returned `Raster` will have the same dimensions as `Rasterstack` that is passed in.
"""
function get_σₚ(Sₐ::Raster, Θ::Raster, p::Number, find_nm::Raster)

    σₚ = similar(Array(Sₐ))
    @. σₚ[find_nm] = GibbsSeaWater.gsw_rho(Sₐ[find_nm], Θ[find_nm], p)

    return Raster(σₚ, dims(Sₐ))

end
function get_σₚ(Sₐ::Raster, Θ::Raster, p::Number)

    Sₐ, Θ = read(Sₐ), read(Θ)
    find_nm = @. !ismissing(Sₐ) && !ismissing(Θ)

    return get_σₚ(Sₐ, Θ, p, find_nm)

end
get_σₚ(stack::RasterStack, var_names::NamedTuple) = get_σₚ(stack[var_names.Sₐ],
                                                           stack[var_names.Θ], var_names.p)
get_σₚ(series::RasterSeries, var_names::NamedTuple) = get_σₚ.(series, Ref(var_names))
