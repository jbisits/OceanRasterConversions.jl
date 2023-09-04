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
