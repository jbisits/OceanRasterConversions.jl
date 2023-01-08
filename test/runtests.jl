using OceanRasterConversions, Test, Rasters, GibbsSeaWater

include("test_oceanrasterconversions.jl")

@testset "RasterStack conversions" begin

    ## `depth_to_pressure`
    @test isequal(converted_p, p)
    ## `Sₚ_to_Sₐ`
    @test isequal(converted_Sₚ, Sₐ_)
    ## `θ_to_Θ`
    @test isequal(converted_θ, Θ)
    ## `convert_ocean_vars`
    # In situ density
    for (i, var) ∈ enumerate(test_vars_in_situ)
        @test isequal(rs_stack_res_in_situ[var], vars_in_situ[i])
    end

    # Potential density
    for (i, var) ∈ enumerate(test_vars_pd)
        @test isequal(rs_stack_res_pd[var], vars_pd[i])
    end
end

@testset "RasterSeries conversions" begin

    ## `Sₚ_to_Sₐ`
    @test isequal(converted_Sₚ_series, Sₐ_)
    ## `θ_to_Θ`
    @test isequal(converted_θ_series, Θ)

    ## `convert_ocean_vars`
    # In situ density
    for t ∈ eachindex(rs_series)
        for (i, var) ∈ enumerate(test_vars_in_situ)
            @test isequal(rs_series_res_in_situ[Ti(t)][var], vars_in_situ[i][:, :, :, t])
        end
    end
    # Potential density
    for t ∈ eachindex(rs_series)
        for (i, var) ∈ enumerate(test_vars_pd)
            @test isequal(rs_series_res_pd[Ti(t)][var], vars_pd[i][:, :, :, t])
        end
    end
end
