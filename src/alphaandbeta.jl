"""
    function get_α(Sₐ::Raster, Θ::Raster, p::Raster)
    function get_α(stack::RasterStack, var_names::NamedTuple)
    function get_α(series::RasterSeries, var_names::NamedTuple)
Compute the thermal exapnsion coefficient, `α`, using `gsw_alpha` from GibbsSeaWater.jl.
To compute `α` from a `RasterStack` or `RasterSeries` the variable names must be passed into the
function as a `NamedTuple` in the form `(Sₐ = :salt_var, Θ = :temp_var, p = :pressure_var)`.
The returned `Raster` will have the same dimensions as `Rasterstack` that is passed in.
"""
function get_α(Sₐ::Raster, Θ::Raster, p::Raster, find_nm::Raster)

    α = similar(Sₐ)
    @. α[find_nm] = GibbsSeaWater.gsw_alpha(Sₐ[find_nm], Θ[find_nm], p[find_nm])

    return Raster(α, dims(Sₐ))

end
function get_α(Sₐ::Raster, Θ::Raster, p::Raster)

    Sₐ, Θ, p = read(Sₐ), read(Θ), read(p)
    find_nm = @. !ismissing(Sₐ) && !ismissing(Θ)

    return get_α(Sₐ, Θ, p, find_nm)

end
get_α(stack::RasterStack, var_names::NamedTuple) = get_α(stack[var_names.Sₐ],
                                                         stack[var_names.Θ],
                                                         stack[var_names.p])
get_α(series::RasterSeries, var_names::NamedTuple) = get_α.(series, Ref(var_names))

"""
    function get_β(Sₐ::Raster, Θ::Raster, p::Raster)
    function get_β(stack::RasterStack, var_names::NamedTuple)
    function get_β(series::RasterSeries, var_names::NamedTuple)
Compute the haline contraction coefficient, `β`, using `gsw_beta` from GibbsSeaWater.jl.
To compute `β` from a `RasterStack` or `RasterSeries` the variable names must be passed into the
function as a `NamedTuple` in the form `(Sₐ = :salt_var, Θ = :temp_var, p = :pressure_var)`.
The returned `Raster` will have the same dimensions as `Rasterstack` that is passed in.
"""
function get_β(Sₐ::Raster, Θ::Raster, p::Raster, find_nm::Raster)

    β = similar(Sₐ)
    @. β[find_nm] = GibbsSeaWater.gsw_beta(Sₐ[find_nm], Θ[find_nm], p[find_nm])

    return Raster(β, dims(Sₐ))

end
function get_β(Sₐ::Raster, Θ::Raster, p::Raster)

    Sₐ, Θ, p = read(Sₐ), read(Θ), read(p)
    find_nm = @. !ismissing(Sₐ) && !ismissing(Θ)

    return get_β(Sₐ, Θ, p, find_nm)

end
get_β(stack::RasterStack, var_names::NamedTuple) = get_β(stack[var_names.Sₐ],
                                                         stack[var_names.Θ],
                                                         stack[var_names.p])
get_β(series::RasterSeries, var_names::NamedTuple) = get_β.(series, Ref(var_names))
