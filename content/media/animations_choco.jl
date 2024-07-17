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

# Model ==========================================================================================
# Mixture
Choco = function (p0, μ0, ϕ0, μ1, ϕ1)
    return MixtureModel(
        [
            0.5 + (-0.5 * Beta(μ0 * ϕ0, (1 - μ0) * ϕ0)),
            0.5 + (0.5 * Beta(μ1 * ϕ1, (1 - μ1) * ϕ1))
        ], [p0, 1 - p0])
end

p0 = Observable(0.5)
μ0 = Observable(0.5)
ϕ0 = Observable(10)
μ1 = Observable(0.5)
ϕ1 = Observable(10)


fig = Figure()
ax1 = Axis(fig[1, 1],
    title=@lift("Choco(p0 = $(round($p0, digits = 2)), μ0 = $(round($μ0, digits = 2)), ϕ0 = $(round($ϕ0, digits = 2)), μ1 = $(round($μ1, digits = 2)), ϕ1 = $(round($ϕ1, digits = 2))"),
    xlabel="Score",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false)
ylims!(ax1; low=0)

xaxis = range(0, 1, length=100)
band!(ax1, xaxis, 0, @lift(pdf.(Choco($p0, $μ0, $ϕ0, $μ1, $ϕ1), xaxis)), color=xaxis, colormap=:curl, colorrange=(0, 1))

fig




# Animate ==========================================================================================
function make_animation(frame)
    if frame < 0.15
        μ0[] = change_param(frame; frame_range=(0, 0.15), param_range=(0.50, 0.95))
        μ1[] = change_param(frame; frame_range=(0, 0.15), param_range=(0.50, 0.05))
    end
    # if frame >= 0.25 && frame < 0.45
    #     μ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.5, 0.2))
    #     σ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.46, 0.2))
    # end
    # if frame >= 0.50 && frame < 0.65
    #     μ[] = change_param(frame; frame_range=(0.50, 0.65), param_range=(0.2, 0.85))
    #     σ[] = change_param(frame; frame_range=(0.50, 0.65), param_range=(0.2, 0.1))
    # end
    # Return to normal
    if frame >= 0.7 && frame < 0.9
        μ0[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.95, 0.50))
        μ1[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.05, 0.50))
    end
    ylims!(ax1; low=0)
end

# animation settings
frames = range(0, 1, length=240)
record(make_animation, fig, "scales_ChocoDistribution.gif", frames; framerate=15)

# Model ==========================================================================================
using CSV
using DataFrames
using Distributions
using SequentialSamplingModels
using GLMakie
using Downloads
using Random
using Turing
using StatsFuns: logistic
using Dates

# lines(range(0, 10, length=1000), pdf.(Gamma(2, 2), range(0, 10, length=1000)))

Choco = function (p0, μ0, ϕ0, μ1, ϕ1)
    return MixtureModel(
        [
            0.5 + (-0.5 * Beta(μ0 * ϕ0, (1 - μ0) * ϕ0)),
            0.5 + (0.5 * Beta(μ1 * ϕ1, (1 - μ1) * ϕ1))
        ], [p0, 1 - p0])
end

@model function model_choco(y)
    p0 ~ Normal(0, 1)
    μ0 ~ Normal(0, 1)
    ϕ0 ~ Gamma(2, 2)
    μ1 ~ Normal(0, 1)
    ϕ1 ~ Gamma(2, 2)

    for i in 1:length(y)
        y[i] ~ Choco(logistic(p0), logistic(μ0), ϕ0, logistic(μ1), ϕ1)
    end
end

function get_results(p0, μ0, ϕ0, μ1, ϕ1)
    y = rand(Choco(p0, μ0, ϕ0, μ1, ϕ1), 10_000)
    t0 = now()
    chains = sample(model_choco(y), NUTS(), 400, init_values=[p0, μ0, ϕ0, μ1, ϕ1])
    t1 = now()
    rez = DataFrame(mean(chains))
    rez.mean[[1, 2, 4]] = logistic.(rez.mean[[1, 2, 4]])
    rez.value = [p0, μ0, ϕ0, μ1, ϕ1]
    rez.duration .= t1 - t0
    return rez
end

# p0 = 0.5
df = DataFrame()
for p0 in range(0.05, 0.95, length=10)
    try
        rez = get_results(p0, 0.5, 10, 0.5, 10)
        df = vcat(df, rez)
    catch e
        rez = DataFrame(
            parameters=[:p0, :μ0, :ϕ0, :μ1, :ϕ1],
            mean=[missing, missing, missing, missing, missing],
            value=[p0, 0.5, 10, 0.5, 10],
            duration=missing)
        df = vcat(df, rez)
    end
end
df

lines(range(0, 1, length=100000), pdf.(Choco(0.5, 0.3, 5, 0.3, 5), range(0, 1, length=100000)))

