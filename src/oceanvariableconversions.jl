"""
    function convert_ocean_vars(raster::RasterStack, var_names::NamedTuple;
                                ref_pressure = nothing,
                                with_α = false,
                                with_β = false)
    function convert_ocean_vars(raster::Rasterseries, var_names::NamedTuple;
                                ref_pressure = nothing,
                                with_α = false,
                                with_β = false)
Convert ocean variables depth, practical salinity and potential temperature to pressure,
absolute salinity and conservative temperature. All conversions are done using the julia
implementation of TEOS-10 [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl). A
new `Raster` is returned that contains the variables pressure, absolute salinity, conservative
temperature and density (either in-situ or referenced to a user defined reference pressure).
As pressure depends on latitude and depth, it is added as a new variable --- that is, each
longitude, latitude, depth and time have a variable for pressure. A density variable is also
computed which, by default, is _in-situ_ density. Potential density at a reference pressure
can be computed instead by passing a the keyword argument `ref_pressure`.
Optional keyword arguments `with_α` and `with_β` allow the thermal expansion and haline
contraction coefficients (respectively) to be computed and added to the returned
`RasterStack/Series`.

The name of the variables for potential temperature and practical salinity must be passed in
as a `NamedTuple` of the form `(Sₚ = :salt_name, θ = :potential_temp_name)` where
`:potential_temp_name` and `:salt_name` are the name of the potential temperature and
practical salinity in the `Raster`.
"""
function convert_ocean_vars(stack::RasterStack, var_names::NamedTuple;
                            ref_pressure = nothing,
                            with_α = false,
                            with_β = false)

    Sₚ = read(stack[var_names.Sₚ])
    θ = read(stack[var_names.θ])
    rs_dims = get_dims(Sₚ)
    p = depth_to_pressure(Sₚ, rs_dims)
    find_nm = @. !ismissing(Sₚ) && !ismissing(θ)
    Sₐ = Sₚ_to_Sₐ(Sₚ, p, rs_dims, find_nm)
    Θ = θ_to_Θ(θ, Sₐ, rs_dims, find_nm)
    converted_vars = isnothing(ref_pressure) ?
                (p = p, Sₐ = Sₐ, Θ = Θ, ρ = get_ρ(Sₐ, Θ, p, find_nm)) :
                (p = p, Sₐ = Sₐ, Θ = Θ, σₚ = get_σₚ(Sₐ, Θ, ref_pressure, find_nm))
    if with_α
        merge(converted_vars, (α = get_α(Sₐ, Θ, p, find_nm),))
    end
    if with_β
        merge(converted_vars, (β = get_β(Sₐ, Θ, p, find_nm),))
    end

    return RasterStack(converted_vars, rs_dims)

end
convert_ocean_vars(series::RasterSeries, var_names::NamedTuple;
                  ref_pressure = nothing,
                  with_α = false,
                  with_β = false) = convert_ocean_vars.(series, Ref(var_names);
                                                                ref_pressure, with_α, with_β)

"""
    function depth_to_pressure(raster::Raster)
    function depth_to_pressure(stack::RasterStack)
Convert the depth dimension (`Z`) to pressure using `gsw_p_from_z`  from GibbsSeaWater.jl.
Note that pressure depends on depth and _latitude_ so the returned pressure is stored as a
variable in the resulting `Raster` rather than replacing the vertical depth dimension.
"""
function depth_to_pressure(raster::Raster, rs_dims::Tuple)

    lons, lats, z, time = rs_dims
    p = similar(Array(raster))

    if isnothing(time)

        lats_array = repeat(Array(lats); outer = (1, length(lons), length(z)))
        lats_array = permutedims(lats_array, (2, 1, 3))
        z_array = repeat(Array(z); outer = (1, length(lons), length(lats)))
        z_array = permutedims(z_array, (2, 3, 1))
        @. p = GibbsSeaWater.gsw_p_from_z(z_array, lats_array)
        rs_dims = (lons, lats, z)

    else

        lats_array = repeat(Array(lats); outer = (1, length(lons), length(z), length(time)))
        lats_array = permutedims(lats_array, (2, 1, 3, 4))
        z_array = repeat(Array(z); outer = (1, length(lons), length(lats), length(time)))
        z_array = permutedims(z_array, (2, 3, 1, 4))
        @. p = GibbsSeaWater.gsw_p_from_z(z_array, lats_array)

    end

    return Raster(p, rs_dims)

end
depth_to_pressure(raster::Raster) = depth_to_pressure(read(raster), get_dims(raster))
depth_to_pressure(stack::RasterStack) = depth_to_pressure(read(stack[keys(stack)[1]]),
                                                          get_dims(stack[keys(stack)[1]]))
"""
    function Sₚ_to_Sₐ(Sₚ::Raster)
    function Sₚ_to_Sₐ(stack::RasterStack, Sₚ::Symbol)
    function Sₚ_to_Sₐ(series::RasterSeries, Sₚ::Symbol)
Convert a `Raster` of practical salinity (`Sₚ`) to absolute salinity (`Sₐ`) using
`gsw_sa_from_sp` from GibbsSeaWater.jl. This conversion depends on pressure.
If converting from a `RasterStack` or `RasterSeries`, the symbol for the practical salinity
in the `RasterStack/Series` must be passed in as a `Symbol` ---  that is if the variable
name is SALT the `RasterStack/Series`, the `Symbol` `:SALT` must be passed in.
"""
function Sₚ_to_Sₐ(Sₚ::Raster, p::Raster, rs_dims::Tuple, find_nm::Raster)

    lons, lats, z, time = rs_dims
    Sₐ = similar(Array(Sₚ))

    if isnothing(time)

        lons_array = repeat(Array(lons); outer = (1, length(lats), length(z)))
        lats_array = repeat(Array(lats); outer = (1, length(lons), length(z)))
        lats_array = permutedims(lats_array, (2, 1, 3))
        @. Sₐ[find_nm] = GibbsSeaWater.gsw_sa_from_sp(Sₚ[find_nm], p[find_nm],
                                                      lons_array[find_nm],
                                                      lats_array[find_nm])

        rs_dims = (lons, lats, z)

    else

        lons_array = repeat(Array(lons); outer = (1, length(lats), length(z), length(time)))
        lats_array = repeat(Array(lats); outer = (1, length(lons), length(z), length(time)))
        lats_array = permutedims(lats_array, (2, 1, 3, 4))
        @. Sₐ[find_nm] = GibbsSeaWater.gsw_sa_from_sp(Sₚ[find_nm], p[find_nm],
                                                      lons_array[find_nm],
                                                      lats_array[find_nm])
    end

    return Raster(Sₐ, rs_dims)

end
function Sₚ_to_Sₐ(Sₚ::Raster)

    Sₚ = read(Sₚ)
    rs_dims = get_dims(Sₚ)
    p = depth_to_pressure(Sₚ, rs_dims)
    find_nm = @. !ismissing(Sₚ)

    return Sₚ_to_Sₐ(Sₚ, p, rs_dims, find_nm)

end
Sₚ_to_Sₐ(stack::RasterStack, Sₚ::Symbol) = Sₚ_to_Sₐ(stack[Sₚ])
Sₚ_to_Sₐ(series::RasterSeries, Sₚ::Symbol) = Sₚ_to_Sₐ.(series, Sₚ)

"""
    function θ_to_Θ(θ::Raster, Sₐ::Raster)
    function θ_to_Θ(stack::RasterStack, var_names::NamedTuple)
    function θ_to_Θ(series::RasterSeries, var_names::NamedTuple)
Convert a `Raster` of potential temperature (`θ`) to conservative temperature (`Θ`) using
`gsw_ct_from_pt`  from GibbsSeaWater.jl. This conversion depends on absolute salinity.
If converting from a  from a
`RasterStack` or a `RasterSeries`, the `var_names` must be passed in as for
`convert_ocean_vars` ---  that is, as a named tuple in the form
`(Sₚ = :salt_name, θ = :potential_temp_name)` where `:potential_temp_name` and
`:salt_name` are the name of the potential temperature and salinity in the `RasterStack`.
"""
function θ_to_Θ(θ::Raster, Sₐ::Raster, rs_dims::Tuple, find_nm::Raster)

    lons, lats, z, time = rs_dims
    Θ = similar(Array(θ))

    if isnothing(time)

        @. Θ[find_nm] = GibbsSeaWater.gsw_ct_from_pt(Sₐ[find_nm], θ[find_nm])
        rs_dims = (lons, lats, z)

    else

        @. Θ[find_nm] = GibbsSeaWater.gsw_ct_from_pt(Sₐ[find_nm], θ[find_nm])

    end

    return Raster(Θ, rs_dims)

end
function θ_to_Θ(θ::Raster, Sₐ::Raster)

    θ = read(θ)
    rs_dims = get_dims(θ)
    find_nm = @. !ismissing(θ) && !ismissing(Sₐ)

    return θ_to_Θ(θ, Sₐ, rs_dims, find_nm)

end
θ_to_Θ(stack::RasterStack, var_names::NamedTuple) = θ_to_Θ(stack[var_names.θ],
                                                           Sₚ_to_Sₐ(stack[var_names.Sₚ]))
θ_to_Θ(series::RasterSeries, var_names::NamedTuple) = θ_to_Θ.(series, Ref(var_names))

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

"""
    function get_dims(raster::Raster)
Get the dimensions of a `Raster`.
"""
function get_dims(raster::Raster)

    rs_dims = if length(dims(raster))==4
                (dims(raster, X), dims(raster, Y),
                dims(raster, Z), dims(raster, Ti))
              elseif !hasdim(raster, X)
                throw(ArgumentError(
                "To compute the absolute salinity variable the longitude dimension, `X`, is required."))
              elseif !hasdim(raster, Y)
                throw(ArgumentError(
                "To compute the pressure variable the latitude dimension,`Y`, is required."))
              elseif !hasdim(raster, Z)
                throw(ArgumentError(
                "To compute the pressure variable the depth dimension, `Z`, is required."))
              elseif !hasdim(raster, Ti)
                (dims(raster, X), dims(raster, Y),
                dims(raster, Z), nothing)
              end

    return rs_dims

end

end #module
