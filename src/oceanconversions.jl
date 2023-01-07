"""
    function convert_ocean_vars(raster::RasterStack, var_names::NamedTuple)
    function convert_ocean_vars(raster::Rasterseries, var_names::NamedTuple)
Convert ocean variables depth, practical salinity and potential temperature to pressure,
absolute salinity and conservative temperature. All conversions are done using the julia
implementation of TEOS-10 [GibbsSeaWater](https://github.com/TEOS-10/GibbsSeaWater.jl). A
new raster is returned that contains the variables pressure, absolute salinity, conservative
temperature and density (either in-situ or referenced to a user defined reference pressure).
As pressure depends on latitude and depth, it is added as a new variable --- that is, each
longitude, latitude, depth and time have a variable for pressure. A density variable is also
computed which, by default, is _in-situ_ density. Potential density at a reference pressure
can be computed instead by passing a the keyword argument `ref_pressure`.

The name of the variables for potential temperature and salinity
(either practical or absolute) must be passed in as a named tuple of the form
`(sp = :salt_name, pt = :potential_temp_name)` where `:potential_temp_name` and `:salt_name`
are the name of the potential temperature and salinity in the `Raster`.

**NOTE**
Currently this is only available for `RasterStacks`s or `RasterSeries`s with `X`, `Y`, `Z`
or `X`, `Y`, `Z`, `Ti` `dims`. If the `RasterStack/Series` has different dimensions e.g.
`X`, `Y`, `Ti` `convert_ocean_vars` will assume that the `Ti` dimension is depth (`Z`) and
compute incorrect variables. Though for pressure we require _at least_ `Y` (latitude) and
`Z` depth so it would not make sense to use this function if there is no depth `dim`.
If more methods are needed for different configurations of `dims` pleas raise an issue on
GitHub.
"""
function convert_ocean_vars(stack::RasterStack, var_names::NamedTuple;
                            ref_pressure = nothing)

    Sₚ = stack[var_names.sp]
    θ = stack[var_names.pt]
    rs_dims = length(dims(Sₚ))==4 ? (dims(Sₚ, X), dims(Sₚ, Y), dims(Sₚ, Z), dims(Sₚ, Ti)) :
                                    (dims(Sₚ, X), dims(Sₚ, Y), dims(Sₚ, Z), nothing)
    p = depth_to_pressure(Sₚ, rs_dims)
    find_nm = @. !ismissing(stack[:Sₚ]) && !ismissing(stack[:θ])
    Sₐ = Sₚ_to_Sₐ(Sₚ, p, rs_dims, find_nm)
    Θ = θ_to_Θ(θ, Sₐ, rs_dims, find_nm)
    converted_vars = isnothing(ref_pressure) ?
                (p = p, Sₐ = Sₐ, Θ = Θ, ρ = in_situ_density(Sₐ, Θ, p, rs_dims, find_nm)) :
                (p = p, Sₐ = Sₐ, Θ = Θ,
                 σₚ = potential_density(Sₐ, Θ, ref_pressure, rs_dims, find_nm))

    return RasterStack(converted_vars, rs_dims)

end
function convert_ocean_vars(series::RasterSeries, var_names::NamedTuple; ref_pressure = nothing)

    rs_array = Array{RasterStack}(undef, length(series))
    for i ∈ eachindex(series)
        rs_array[i] = convert_ocean_vars(series[i], var_names; ref_pressure)
    end

    return RasterSeries(rs_array, dims(series, Ti))

end

"""
    function depth_to_pressure(raster::Raster)
Convert the depth dimension (`Z`) to pressure using `gsw_p_from_z`  from GibbsSeaWater.jl.
Note that pressure depends on depth and _latitude_ so the returned pressure is stored as a
variable in the resulting `Raster` rather than replacing the vertical depth dimension.
"""
function depth_to_pressure(raster::Raster, rs_dims::Tuple)

    lons, lats, z, time = rs_dims
    p = similar(Array(raster))

    if isnothing(time)

        lats_array = repeat(Array(lats)'; outer = (length(lons), 1, length(z)))
        z_array = repeat(Array(z); outer = (1, length(lons), length(lats)))
        z_array = permutedims(z_array, (2, 3, 1))
        @. p = GibbsSeaWater.gsw_p_from_z(z_array, lats_array)
        rs_dims = (lons, lats, z)

    else

        lats_array = repeat(Array(lats)'; outer = (length(lons), 1, length(z), length(time)))
        z_array = repeat(Array(z); outer = (1, length(lons), length(lats), length(time)))
        z_array = permutedims(z_array, (2, 3, 1, 4))
        @. p = GibbsSeaWater.gsw_p_from_z(z_array, lats_array)

    end

    return Raster(p, rs_dims)

end

"""
    function Sₚ_to_Sₐ(raster::Raster, p::raster, rs_dims::Tuple, find_nm::Raster)
Convert a `Raster` of practical salinity (`Sₚ`) to absolute salinity (`Sₐ`) using
`gsw_sa_from_sp` from GibbsSeaWater.jl.
"""
function Sₚ_to_Sₐ(Sₚ::Raster, p::Raster, rs_dims::Tuple, find_nm::Raster)

    lons, lats, z, time = rs_dims
    Sₐ = similar(Array(Sₚ), Union{Float64, Missing})

    if isnothing(time)

        lons_array = repeat(Array(lons); outer = (1, length(lats), length(z)))
        lats_array = repeat(Array(lats)'; outer = (length(lons), 1, length(z)))
        @. Sₐ[find_nm] = GibbsSeaWater.gsw_sa_from_sp(Sₚ[find_nm], p[find_nm],
                                                      lons_array[find_nm],
                                                      lats_array[find_nm])

        rs_dims = (lons, lats, z)

    else

        lons_array = repeat(Array(lons); outer = (1, length(lats), length(z), length(time)))
        lats_array = repeat(Array(lats)'; outer = (length(lons), 1, length(z), length(time)))
        @. Sₐ[find_nm] = GibbsSeaWater.gsw_sa_from_sp(Sₚ[find_nm], p[find_nm],
                                                      lons_array[find_nm],
                                                      lats_array[find_nm])
    end

    return Raster(Sₐ, rs_dims)

end

"""
    function θ_to_Θ(raster::Raster, Sₐ::raster, rs_dims::Tuple, find_nm::Raster)
Convert a `Raster` of potential temperature (`θ`) to conservative temperature (`Θ`) using
`gsw_ct_from_pt`  from GibbsSeaWater.jl. This conversion depends on absolute salinity.
"""
function θ_to_Θ(θ::Raster, Sₐ::Raster, rs_dims::Tuple, find_nm::Raster)

    lons, lats, z, time = rs_dims
    Θ = similar(Array(θ), Union{Float64, Missing})

    if isnothing(time)

        @. Θ[find_nm] = GibbsSeaWater.gsw_ct_from_pt(Sₐ[find_nm], θ[find_nm])
        rs_dims = (lons, lats, z)

    else

        @. Θ[find_nm] = GibbsSeaWater.gsw_ct_from_pt(Sₐ[find_nm], θ[find_nm])

    end

    return Raster(Θ, rs_dims)

end

"""
    function in_situ_density(Sₐ::Raster, Θ::Raster, p::Raster, rs_dims::Tuple, find_nm::Raster)
Compute in-situ density using `gsw_rho` from GibbsSeaWater.jl.
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
    function potential_density(Sₐ::Raster, Θ::Raster, p::Float64, rs_dims::Tuple, find_nm::Raster)
Compute potential density at reference pressure `p`, `σₚ`, using `gsw_rho`  from GibbsSeaWater.jl.
"""
function potential_density(Sₐ::Raster, Θ::Raster, p::Float64, rs_dims::Tuple, find_nm::Raster)

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
