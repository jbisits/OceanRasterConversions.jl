"""
    function convert_ocean_vars(raster::RasterStack, var_names::NamedTuple;
                                ref_pressure = nothing)
    function convert_ocean_vars(raster::Rasterseries, var_names::NamedTuple;
                                ref_pressure = nothing)
Convert ocean variables depth, practical salinity and potential temperature to pressure,
absolute salinity and conservative temperature. All conversions are done using the julia
implementation of TEOS-10 [GibbsSeaWater.jl](https://github.com/TEOS-10/GibbsSeaWater.jl). A
new `Raster` is returned that contains the variables pressure, absolute salinity, conservative
temperature and density (either in-situ or referenced to a user defined reference pressure).
As pressure depends on latitude and depth, it is added as a new variable --- that is, each
longitude, latitude, depth and time have a variable for pressure. A density variable is also
computed which, by default, is _in-situ_ density. Potential density at a reference pressure
can be computed instead by passing a the keyword argument `ref_pressure`.

The name of the variables for potential temperature and practical salinity must be passed in
as a `NamedTuple` of the form `(Sₚ = :salt_name, θ = :potential_temp_name)` where
`:potential_temp_name` and `:salt_name` are the name of the potential temperature and
practical salinity in the `Raster`.
"""
function convert_ocean_vars(stack::RasterStack, var_names::NamedTuple;
                            ref_pressure = nothing)

    Sₚ = read(stack[var_names.Sₚ])
    θ = read(stack[var_names.θ])
    rs_dims = get_dims(Sₚ)
    p = depth_to_pressure(Sₚ, rs_dims)
    find_nm = @. !ismissing(Sₚ) && !ismissing(θ)
    Sₐ = Sₚ_to_Sₐ(Sₚ, p, rs_dims, find_nm)
    Θ = θ_to_Θ(θ, Sₐ, rs_dims, find_nm)
    converted_vars = isnothing(ref_pressure) ?
                (p = p, Sₐ = Sₐ, Θ = Θ, ρ = in_situ_density(Sₐ, Θ, p, rs_dims, find_nm)) :
                (p = p, Sₐ = Sₐ, Θ = Θ,
                 σₚ = potential_density(Sₐ, Θ, ref_pressure, rs_dims, find_nm))

    return RasterStack(converted_vars, rs_dims)

end
convert_ocean_vars(series::RasterSeries, var_names::NamedTuple;
                  ref_pressure = nothing) = convert_ocean_vars.(series, Ref(var_names);
                                                                ref_pressure)

"""
    function depth_to_pressure(raster::Raster, rs_dims::Tuple)
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
"""
    function depth_to_pressure(stack::RasterStack)
Convert the depth dimension `Z` from a `RasterStack`.
"""
depth_to_pressure(stack::RasterStack) = depth_to_pressure(stack[keys(stack)[1]],
                                                          get_dims(stack[keys(stack)[1]]))
"""
    function Sₚ_to_Sₐ(raster::Raster, p::raster, rs_dims::Tuple, find_nm::Raster)
Convert a `Raster` of practical salinity (`Sₚ`) to absolute salinity (`Sₐ`) using
`gsw_sa_from_sp` from GibbsSeaWater.jl. This conversion depends on pressure.
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
"""
    function Sₚ_to_Sₐ(stack::RasterStack, Sₚ::Symbol)
    function Sₚ_to_Sₐ(series::RasterSeries, Sₚ::Symbol)
Convert only the practical salinity, returning the absolute salinity, from a `RasterStack`
or `RasterSeries`. The symbol for the practical salinity in the `RasterStack/Series` must be
passed in.
"""
Sₚ_to_Sₐ(stack::RasterStack, Sₚ::Symbol) = Sₚ_to_Sₐ(stack[Sₚ],
                                                    depth_to_pressure(stack),
                                                    get_dims(stack[Sₚ]),
                                                    .!ismissing.(stack[Sₚ]))
Sₚ_to_Sₐ(series::RasterSeries, Sₚ::Symbol) = Sₚ_to_Sₐ.(series, Sₚ)

"""
    function θ_to_Θ(raster::Raster, Sₐ::raster, rs_dims::Tuple, find_nm::Raster)
Convert a `Raster` of potential temperature (`θ`) to conservative temperature (`Θ`) using
`gsw_ct_from_pt`  from GibbsSeaWater.jl. This conversion depends on absolute salinity.
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
"""
    function θ_to_Θ(stack::RasterStack, var_names::NamedTuple)
    function θ_to_Θ(series::RasterSeries, var_names::NamedTuple)
Convert the potential temperature, returning only the conservative temperature, from a
`RasterStack` or a `RasterSeries`. The `var_names` must be passed in as for
`convert_ocean_vars` ---  that is, as a named tuple in the form
`(Sₚ = :salt_name, θ = :potential_temp_name)` where `:potential_temp_name` and
`:salt_name` are the name of the potential temperature and salinity in the `Raster`.
"""
θ_to_Θ(stack::RasterStack, var_names::NamedTuple) = θ_to_Θ(stack[var_names.θ],
                                                           Sₚ_to_Sₐ(stack, var_names.Sₚ),
                                                           get_dims(stack[var_names.θ]),
                                                           .!ismissing.(stack[var_names.θ]) .&&
                                                           .!ismissing.(stack[var_names.Sₚ]))
θ_to_Θ(series::RasterSeries, var_names::NamedTuple) = θ_to_Θ.(series, Ref(var_names))

"""
    function in_situ_density(Sₐ::Raster, Θ::Raster, p::Raster, rs_dims::Tuple, find_nm::Raster)
Compute in-situ density using `gsw_rho` from GibbsSeaWater.jl. This conversion depends on
absolute salinity (`Sₐ`), conservative temperature (`Θ`) and pressure (`p`).
"""
function in_situ_density(Sₐ::Raster, Θ::Raster, p::Raster, rs_dims::Tuple, find_nm::Raster)

    lons, lats, z, time = rs_dims
    ρ = similar(Array(Θ))

    if isnothing(time)

        @. ρ[find_nm] = GibbsSeaWater.gsw_rho(Sₐ[find_nm], Θ[find_nm], p[find_nm])
        rs_dims = (lons, lats, z)

    else

        @. ρ[find_nm] = GibbsSeaWater.gsw_rho(Sₐ[find_nm], Θ[find_nm], p[find_nm])

    end

    return Raster(ρ, rs_dims)

end
"""
    function in_situ_density(stack::RasterStack, var_names::NamedTuple)
    function in_situ_density(series::RasterStack, var_names::NamedTuple)
Compute and return the in-situ density `ρ` from a `RasterStack` or `RasterSeries`.
This computation depends on absolute salinity `Sₐ`, conservative temperature `Θ`
and pressure `p`. The variable names must be passed into the function as a `NamedTuple` in
the form `(Sₐ = :salt_var, Θ = :temp_var, p = :pressure_var)`.
"""
in_situ_density(stack::RasterStack, var_names::NamedTuple) =
    in_situ_density(stack[var_names.Sₐ], stack[var_names.Θ], stack[var_names.p],
                    get_dims(stack[var_names.Sₐ]),
                   .!ismissing.(stack[var_names.Sₐ]) .&& .!ismissing.(stack[var_names.Θ]))
in_situ_density(series::RasterSeries, var_names::NamedTuple) = in_situ_density.(series, Ref(var_names))

"""
    function potential_density(Sₐ::Raster, Θ::Raster, p::Float64, rs_dims::Tuple, find_nm::Raster)
Compute potential density at reference pressure `p`, `σₚ`, using `gsw_rho`  from GibbsSeaWater.jl.
This conversion depends on absolute salinity (`Sₐ`), conservative temperature (`Θ`) and a
user entered reference pressure (`p`).
"""
function potential_density(Sₐ::Raster, Θ::Raster, p::Number, rs_dims::Tuple, find_nm::Raster)

    lons, lats, z, time = rs_dims
    σₚ = similar(Array(Θ))

    if isnothing(time)

        @. σₚ[find_nm] = GibbsSeaWater.gsw_rho(Sₐ[find_nm], Θ[find_nm], p)
        rs_dims = (lons, lats, z)

    else

        @. σₚ[find_nm] = GibbsSeaWater.gsw_rho(Sₐ[find_nm], Θ[find_nm], p)

    end

    return Raster(σₚ, rs_dims)

end
"""
    function potential_density(stack::RasterStack, var_names::NamedTuple)
    function potential_density(series::RasterStack, var_names::NamedTuple)
Compute and return the potential density `σₚ` at reference pressure `p` from a
`RasterStack` or `RasterSeries`. This computation depends on absolute salinity `Sₐ`,
conservative temperature `Θ` and a reference pressure `p`. The variable names must be
passed into the function as a `NamedTuple` in the form
`(Sₐ = :salt_var, Θ = :temp_var, p = ref_pressure)`. Note `p` in this case is a number.
"""
potential_density(stack::RasterStack, var_names::NamedTuple) =
    potential_density(stack[var_names.Sₐ], stack[var_names.Θ], var_names.p,
                      get_dims(stack[var_names.Sₐ]),
                      .!ismissing.(stack[var_names.Sₐ]) .&& .!ismissing.(stack[var_names.Θ]))
potential_density(series::RasterSeries, var_names::NamedTuple) = potential_density.(series, Ref(var_names))
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
                "To computes the absolute salinity variable the longitude dimension, `X`, is required."))
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
