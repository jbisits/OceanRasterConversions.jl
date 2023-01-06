using OceanRasterConversions, Test, Rasters, GibbsSeaWater

@testset "ocean conversions" begin

    include("test_oceanrasterconversions.jl")

    ## `RasterStack`s tests
    for (i, var) ∈ enumerate(test_vars)
        ## In situ density stack tests
        @test isequal(rs_stack_res_in_situ[var], vars_in_situ[i])
        ## Potential density stack tests
        @test isequal(rs_stack_res_pd[var], vars_pd[i])
    end

    ## `RasterSeries`s tests
    for t ∈ eachindex(rs_series)
        for (i, var) ∈ enumerate(test_vars)
            # In situ density series tests
            @test isequal(rs_series_res_in_situ[Ti(t)][var], vars_in_situ[i][:, :, :, t])
            # Potenrial density series tests
            @test isequal(rs_series_res_pd[Ti(t)][var], vars_pd[i][:, :, :, t])
        end
    end

end
