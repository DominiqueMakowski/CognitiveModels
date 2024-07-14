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
using Turing, Distributions, Random

# # Reparameterized Beta distribution
# function MeanVarBeta(μ, σ²)
#     if σ² <= 0 || σ² >= μ * (1 - μ)
#         error("Variance σ² must be in the interval (0, μ*(1-μ)=$(μ*(1-μ))).")
#     end

#     ν = μ * (1 - μ) / σ² - 1
#     α = μ * ν
#     β = (1 - μ) * ν

#     return Beta(α, β)
# end
# var(MeanVarBeta(0.3, 0.1))
# mean(MeanVarBeta(0.3, 0.1))

function BetaMean(μ, σ)
    if σ <= 0 || σ >= sqrt(μ * (1 - μ))
        error("Standard deviation σ must be in the interval (0, sqrt(μ*(1-μ))=$(sqrt(μ*(1-μ)))).")
    end
    ν = μ * (1 - μ) / σ^2 - 1
    α = μ * ν
    β = (1 - μ) * ν

    return Beta(α, β)
end
std(BetaMean(0.3, 0.2))
mean(BetaMean(0.3, 0.2))


# Range of possible parameters
fig = Figure()
ax = Axis(fig[1, 1], xlabel="μ", ylabel="variance σ²")
for μ in range(0.0, 1, length=200)
    for σ in range(0, 1, length=200)
        x = range(0, 1, length=100)
        try
            y = pdf.(BetaMean(μ, σ), x)
            scatter!(ax, μ, σ, color=:red)
        catch
            continue
        end
    end
end
ylims!(ax, 0, 0.5)
# ablines!(ax, [0, 1], [1, -1]; color=:black)
xaxis = range(0, 1, length=1000)
lines!(ax, xaxis, xaxis .* (1 .- xaxis); color=:black)
fig

# Figure
fig = Figure()

μ = Observable(0.5)
σ = Observable(0.05)

ax1 = Axis(fig[1, 1], title="Possible parameter range", xlabel="μ", ylabel="σ", yticks=range(0, 0.5, 6))
ylims!(ax1, 0, 0.6)
# ablines!(ax, [0, 1], [1, -1]; color=:black)
xaxis = range(0, 1, length=1000)
yaxis = sqrt.(xaxis .* (1 .- xaxis))
band!(ax1, xaxis, 0, yaxis, color=:orange)
lines!(ax1, xaxis, yaxis; color=:red)
text!(ax1, 0, 0.55, text="max. σ = √(μ * (1 - μ))", align=(:left, :center), color=:red)
scatter!(ax1, @lift([$μ]), @lift([$σ]); color="#2196F3", marker=:xcross, markersize=15)

fig


ax2 = Axis(
    fig[1, 2],
    title=@lift("BetaMean(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)))"),
    xlabel="Score",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
ylims!(ax2, 0, 10)
xlims!(ax2, 0, 1)

x = range(0, 1, length=1000)
y = @lift(pdf.(BetaMean($μ, $σ), x))

band!(ax2, x, 0, y, color="#2196F3")
fig

function make_animation(frame)
    if frame < 0.20
        σ[] = change_param(frame; frame_range=(0.0, 0.20), param_range=(0.05, 0.46))
    end
    if frame >= 0.25 && frame < 0.45
        μ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.5, 0.2))
        σ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.46, 0.2))
    end
    if frame >= 0.50 && frame < 0.65
        μ[] = change_param(frame; frame_range=(0.50, 0.65), param_range=(0.2, 0.85))
        σ[] = change_param(frame; frame_range=(0.50, 0.65), param_range=(0.2, 0.1))
    end
    # Return to normal
    if frame >= 0.7 && frame < 0.9
        μ[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.85, 0.5))
        σ[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.1, 0.05))
    end
end

# animation settings
frames = range(0, 1, length=120)
record(make_animation, fig, "scales_BetaMean.gif", frames; framerate=10)



# BetaMuPhi =====================================================================================
BetaMuPhi(μ, ϕ) = Beta(μ * ϕ, (1 - μ) * ϕ)

# Range of possible parameters
fig = Figure()
ax = Axis(fig[1, 1], xlabel="μ", ylabel="ϕ")
for μ in range(-0.1, 1.1, length=60)
    for ϕ in range(-0.1, 50, length=60)
        x = range(0, 1, length=100)
        try
            y = pdf.(BetaMuPhi(μ, ϕ), x)
            scatter!(ax, μ, ϕ, color=:red)
        catch
            continue
        end
    end
end
# ylims!(ax, 0, 0.5)
# ablines!(ax, [0, 1], [1, -1]; color=:black)
fig


# Figure
fig = Figure()

μ = Observable(0.5)
ϕ = Observable(100.0)

ax1 = Axis(
    fig[1, 1],
    title=@lift("BetaMuPhi(μ = $(round($μ, digits = 1)), ϕ =  $(round($ϕ, digits = 2)))"),
    xlabel="Score",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
xlims!(ax1, 0, 1)
ylims!(ax1, 0, 8)
x = range(0, 1, length=1000)
y = @lift(pdf.(BetaMuPhi($μ, $ϕ), x))
band!(ax1, x, 0, y, color="#2196F3")
fig

function make_animation(frame)
    if frame < 0.20
        ϕ[] = change_param(frame; frame_range=(0.0, 0.20), param_range=(100.0, 0.1))
    end
    if frame >= 0.25 && frame < 0.45
        μ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.5, 0.2))
        ϕ[] = change_param(frame; frame_range=(0.25, 0.45), param_range=(0.1, 5))
    end
    if frame >= 0.50 && frame < 0.65
        μ[] = change_param(frame; frame_range=(0.50, 0.65), param_range=(0.2, 0.90))
        ϕ[] = change_param(frame; frame_range=(0.50, 0.65), param_range=(5, 25))
    end
    # Return to normal
    if frame >= 0.7 && frame < 0.9
        μ[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(0.90, 0.5))
        ϕ[] = change_param(frame; frame_range=(0.7, 0.9), param_range=(25, 100))
    end
end

# animation settings
frames = range(0, 1, length=240)
record(make_animation, fig, "scales_BetaMuPhi.gif", frames; framerate=15)