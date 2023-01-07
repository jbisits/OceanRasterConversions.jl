using OceanRasterConversions, Test, Rasters, GibbsSeaWater

@testset "ocean conversions" begin

    include("test_oceanrasterconversions.jl")

    ## `RasterStack`s tests
    # In situ density
    for (i, var) ∈ enumerate(test_vars_in_situ)
        @test isequal(rs_stack_res_in_situ[var], vars_in_situ[i])
    end

    # Potential density
    for (i, var) ∈ enumerate(test_vars_pd)
        @test isequal(rs_stack_res_pd[var], vars_pd[i])
    end

    ## `RasterSeries`s tests
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
