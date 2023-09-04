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
