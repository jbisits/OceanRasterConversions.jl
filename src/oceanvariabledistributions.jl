#=
Extend `StatsBase.fit` to accept a `Raster`, an `NTuple` of `Rasters` a `RasterStack` or a
`RasterSeries` as inputs and produce an N-dimensional `Histogram`.
Note that for a `RasterStack` the variables that the `Histogram` is to be produced from need
to be passed in as `Symbol`s contained in a `Tuple`.
=#
StatsBase.fit(::Type{Histogram}, rs::Raster, args...; kwargs...) =
    StatsBase.fit(Histogram, collect(skipmissing(reshape(read(rs), :)[:])), args...;
                  kwargs...)
function StatsBase.fit(::Type{Histogram}, rs::NTuple{N, Raster}, args...; kwargs...) where{N}

    find_nm = @. !ismissing(rs[1]) && !ismissing(rs[2])
    rs_tuple = Tuple(collect(skipmissing(r[find_nm])) for r ∈ rs)

    return StatsBase.fit(Histogram, rs_tuple, args...; kwargs...)

end
function StatsBase.fit(::Type{Histogram}, stack::RasterStack, vars::Tuple{N, Symbol},
                       args...; kwargs...) where{N}

    rs_tuple = Tuple(stack[var] for var ∈ vars)

    return StatsBase.fit(Histogram, rs_tuple, args...; kwargs...)

end
function StatsBase.fit(::Type{Histogram}, series::RasterSeries, vars::Tuple{N, Symbol},
                       args...; kwargs...) where{N}

    rs_tuple = Tuple(series[1][var] for var ∈ vars)
    merged_hist = fit(Histogram, rs_tuple, args...; kwargs...)
    for stack ∈ series[2:end]
        rs_tuple = Tuple(stack[var] for var ∈ vars)
        merge!(merged_hist, fit(Histogram, rs_tuple, args...; kwargs...))
    end

    return merged_hist

end
"""
    function area_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)
Return the `Weights` for a `Histogram` calculated from the area of each grid cell in a
`Raster` or `RasterStack`. The `Raster` or `RasterStack` must first be sliced over the
dimensions one wishes to look at, e.g. for area weights at sea surface the function need
`rs[Z(1)]` to be passed in. If the original `Raster` only has two spatial dimensions then
this step may be skipped.
The keyword argument `equator_one_degree` is one degree at the equator in metres.
The function returns a container `Weights` so can be passed straight into
the `fit(::Histogram)` function.
"""
function area_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)

    rs = typeof(rs) <: RasterStack ? rs[keys(rs)[1]] : rs

    dA =if !hasdim(rs, :Z)
            lon, lat = lookup(rs, X), lookup(rs, Y)
            lon_model_resolution = unique(diff(lon))[1]
            lat_model_resolution = unique(diff(lat))[1]
            dx = (equator_one_degree * lon_model_resolution) .* ones(length(lon))
            dy = (equator_one_degree * lat_model_resolution) .* cos.(deg2rad.(lat))
            dx * dy'
        elseif !hasdim(rs, :Y)
            lon, z = lookup(rs, X), lookup(rs, Z)
            lon_model_resolution = unique(diff(lon))[1]
            dx = (equator_one_degree * lon_model_resolution) .* ones(length(lon))
            dz = diff(abs.(z))
            dz = vcat(dz[1], dz)
            dx * dz'
        elseif !hasdim(rs, :X)
            lat, z = lookup(rs, Y), lookup(rs, Z)
            lat_model_resolution = unique(diff(lat))[1]
            dy = (equator_one_degree * lat_model_resolution) .* cos.(deg2rad.(lat))
            dz = diff(abs.(z))
            dz = vcat(dz[1], dz)
            dy * dz'
        end
    find_nm = reshape(.!ismissing.(rs), :)[:]
    dA_vec = reshape(dA, :)[find_nm]

    return weights(dA_vec)

end
"""
    function volume_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)
Return the `Weights` for a `Histogram` calculated from the volume of each grid cell in a
`Raster` or `RasterStack`. The model resolution is inferred from the `X` and `Y` dimensions
of the `Raster` or `RasterStack` and assumes that along the `X` and `Y` the resolution is
unique (though it can be different for `X` and `Y`).
The keyword argument `equator_one_degree` is one degree at the
equator in metres. The function returns a container `Weights` so can be passed straight into
the `fit(::Histogram)` function.
"""
function volume_weights(rs::Union{Raster, RasterStack}; equator_one_degree = 111e3)

    rs = typeof(rs) <: RasterStack ? rs[keys(rs)[1]] : rs
    lon, lat, z = lookup(rs, X), lookup(rs, Y), lookup(rs, Z)
    lon_model_resolution = unique(diff(lon))[1]
    lat_model_resolution = unique(diff(lat))[1]
    dx = (equator_one_degree * lon_model_resolution) .* ones(length(lon))
    dy = (equator_one_degree * lat_model_resolution) .* cos.(deg2rad.(lat))
    dz = diff(abs.(z))
    dz = vcat(dz[1], dz)
    dV = Array{Float64}(undef, length(dx), length(dy), length(dz))
    for i ∈ axes(dV, 3)
        dV[:, :, i] = (dx .* dy') * dz[i]
    end
    find_nm = reshape(.!ismissing.(rs), :)[:]
    dV_vec = reshape(dV, :)[find_nm]

    return weights(dV_vec)

end
