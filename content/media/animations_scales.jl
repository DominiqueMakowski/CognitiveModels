using CSV
using DataFrames
using Distributions
using SequentialSamplingModels
using GLMakie
using Downloads
using Random

# Data ==========================================================================================
cd(@__DIR__)

function rescale_param(p; original_range=(-1, 1), new_range=(-3, 3))
    p = (p - original_range[1]) / (original_range[2] - original_range[1])
    p = p * (new_range[2] - new_range[1]) + new_range[1]
    return p
end

function change_param(frame; frame_range=(0, 1), param_range=(0, 1))
    frame = rescale_param(frame; original_range=frame_range, new_range=(1π, 2π))
    p = rescale_param(cos(frame); original_range=(-1, 1), new_range=param_range)
    return p
end


# BetaMod =======================================================================================

# Reparameterized Beta distribution
function BetaMod(μ, σ)
    α = μ * (μ * (1 - μ) / σ^2 - 1)
    β = α * (1 - μ) / μ
    return Beta(α, β)
end

μ = Observable(0.5)
σ = Observable(0.1)

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("BetaMod(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)))"),
    xlabel="Score",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
ylims!(ax, 0, 10)

x = range(0, 1, length=100)
y = @lift(pdf.(BetaMod($μ, $σ), x))

lines!(ax, x, y)
fig

function make_animation(frame)
    if frame < 0.15
        μ[] = change_param(frame; frame_range=(0.0, 0.15), param_range=(0.5, 0.9))
    end
    if frame >= 0.25 && frame < 0.45
        μ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.9, 0.1))
    end
    if frame >= 0.55 && frame < 0.65
        σ[] = change_param(frame; frame_range=(0.55, 0.65), param_range=(0.1, 0.3))
    end
    # Return to normal
    if frame >= 0.7 && frame < 0.9
        μ[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.1, 0.5))
        σ[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.3, 0.1))
    end
end

# animation settings
frames = range(0, 1, length=120)
record(make_animation, fig, "scales_betamod.gif", frames; framerate=20)

