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
