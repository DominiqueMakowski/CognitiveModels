using CSV
using DataFrames
using Distributions
using SequentialSamplingModels
using CairoMakie
using Downloads
using Random

# Data ==========================================================================================
cd(@__DIR__)
df = CSV.read(Downloads.download("https://raw.githubusercontent.com/RealityBending/DoggoNogo/main/study1/data/data_game.csv"), DataFrame)


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

# Make plot =====================================================================================

# Parameters
μ = Observable(0.0)
σ = Observable(0.2)

x = range(-0.1, 0.8, length=100)
y = @lift(pdf.(Normal($μ, $σ), x))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("Normal(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)

density!(ax, df.RT, bandwidth=0.01, npoints=1000, color=:grey)
lines!(x, pdf.(fit(Normal, df.RT), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4)
fig

function make_animation(frame)
    if frame < 0.2
        μ[] = change_param(frame; frame_range=(0, 0.2), param_range=(0, 0.5))
    end
    if frame >= 0.2 && frame < 0.4
        μ[] = change_param(frame; frame_range=(0.2, 0.4), param_range=(0.5, 0.3))
    end
    if frame >= 0.4 && frame < 0.6
        σ[] = change_param(frame; frame_range=(0.4, 0.6), param_range=(0.2, 0.05))
    end
    # Return to normal
    if frame >= 0.7
        μ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.3, 0))
        σ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.05, 0.2))
    end
end

# animation settings
frames = range(0, 1, length=60)

record(make_animation, fig, "rt_normal.gif", frames; framerate=30)

plot(cos.(range(1π, 2π, length=100)))
plot(cos.(range(2π, 3π, length=100)))