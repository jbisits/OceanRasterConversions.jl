using OceanRasterConversions, Test, Rasters, GibbsSeaWater, StatsBase

include("test_oceanrasterconversions.jl")

@testset "Raster conversions" begin
    ## `depth_to_pressure`
    @test isequal(converted_p_raster, p)
    ## `Sₚ_to_Sₐ`
    @test isequal(converted_Sₚ_raster, Sₐ_)
    ## `θ_to_Θ`
    @test isequal(converted_θ_raster, Θ)
    ## `get_ρ`
    @test isequal(converted_ρ_raster, ρ)
    ## `get_σₚ`
    @test isequal(converted_σₚ_raster, σₚ)
    ## `get_α`
    @test isequal(converted_α_raster, α)
    ## `get_β`
    @test isequal(converted_β_raster, β)
end

@testset "RasterStack conversions" begin

    ## `depth_to_pressure`
    @test isequal(converted_p_stack, p)
    ## `Sₚ_to_Sₐ`
    @test isequal(converted_Sₚ_stack, Sₐ_)
    ## `θ_to_Θ`
    @test isequal(converted_θ_stack, Θ)
    ## `get_ρ`
    @test isequal(converted_ρ_stack, ρ)
    ## `get_σₚ`
    @test isequal(converted_σₚ_stack, σₚ)
    ## `get_α`
    @test isequal(converted_α_stack, α)
    ## `get_β`
    @test isequal(converted_β_stack, β)

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
     ## `get_ρ`
     @test isequal(converted_ρ_series, ρ)
     ## `get_σₚ`
     @test isequal(converted_σₚ_series, σₚ)
     ## `get_α`
    @test isequal(converted_α_series, α)
    ## `get_β`
    @test isequal(converted_β_series, β)

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

@testset "Argument errors" begin

    @test_throws ArgumentError convert_ocean_vars(rs_stack_NoX, (Sₚ = :Sₚ, θ = :θ))
    @test_throws ArgumentError convert_ocean_vars(rs_stack_NoY, (Sₚ = :Sₚ, θ = :θ))
    @test_throws ArgumentError convert_ocean_vars(rs_stack_NoZ, (Sₚ = :Sₚ, θ = :θ))

end

include("test_oceanvariabledistributions.jl")

@testset "Histograms" begin

    for hf ∈ hist_fields
        @test getproperty(raster_hist, hf) == getproperty(array_hist, hf)
    end

end
