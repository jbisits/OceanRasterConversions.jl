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
