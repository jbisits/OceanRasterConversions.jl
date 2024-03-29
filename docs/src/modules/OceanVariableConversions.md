# [Converting Ocean Variables](@id ocean_conv_vars_module)

## Package workings

This package will convert the variables practical salinity and potential temperature into absolute salinity and conservative temperature.
In doing so a pressure variable is needed, so this is created and returned in the `RasterStack`.
A density variable (either in-situ or potential referenced to a user input) is computed and added to the `RasterStack`.
See the example for how the module can be used.

!!! info
    The only dimension names that are supported are `X`, `Y`, `Z`, and `Ti`.
    Allowing for user specified dimensions has not yet been implemented.

### Variables

The variables are named using the symbols that represent them.
The symbols are unicode characters which can be generated in the julia repl by pressing tab after the varible

```julia
julia> \theta#press tab
```

will autocomplete to `θ`, the symbol for potential temperature.
The subscript letters that are used to distinguish between practical salinity, `Sₚ`, and absolute salinity, `Sₐ`, are also added in the julia repl

```julia
julia> S\_a#press tab
```

Currently the varabile symbols are:

- `θ` potential temperature
- `Θ` conservative temperature
- `Sₚ` practical salinity
- `Sₐ` absolute salinity
- `p` pressure
- `ρ` in-situ seawater density
- `σₚ` potential density at user defined reference pressure `ₚ`
- `α` thermal expansion coefficient
- `β` haline contraction coefficient.

### Limitations

If the required dimensions for the conversions are not present an error will be thrown.
For example, trying to convert a `RasterStack` that has no depth dimension will not work as the `Z` dimension is not found and the pressure variable depends on depth.
There is a manual workaround for this.
When defining the `RasterStack` add the `Z` dimension as a single entry, rather than a `Vector`,

```julia
lons, lats, z = -180:180, -90:90, 0.0
stack = RasterStack(data, (X(lons), Y(lats), Z(z)))
```

This is equivalent to a two dimensional `RasterStack` at sea-surface height (z = 0).

At this stage it is also not possible to slice a `Raster` then convert it.
This is something that will be implemented at some stage.
For details on why this is the case see [this issue](https://github.com/jbisits/OceanRasterConversions.jl/issues/27).
As the example shows it is straightforward to first convert a `Raster` and then slice it.

For a full list of the functions in this module see the [function index](@ref ovc_func_index) or look at the [example](@ref converting_variables_example) to see the module in action.
