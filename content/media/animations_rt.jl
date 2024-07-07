using CSV
using DataFrames
using Distributions
using SequentialSamplingModels
using GLMakie
using Downloads
using Random

# Data ==========================================================================================
cd(@__DIR__)
df = CSV.read(Downloads.download("https://raw.githubusercontent.com/DominiqueMakowski/CognitiveModels/main/data/wagenmakers2008.csv"), DataFrame)


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

# Normal =====================================================================================
# fit(Normal, df.RT)

# Parameters
μ = Observable(0.0)
σ = Observable(0.4)

x = range(-0.1, 2, length=1000)
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

density!(ax, df.RT, npoints=1000, color=:grey)
lines!(x, pdf.(fit(Normal, df.RT), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4, color=:orange)
fig

function make_animation(frame)
    if frame < 0.2
        μ[] = change_param(frame; frame_range=(0, 0.2), param_range=(0, 1))
    end
    if frame >= 0.2 && frame < 0.4
        μ[] = change_param(frame; frame_range=(0.2, 0.4), param_range=(1, 0.58))
    end
    if frame >= 0.4 && frame < 0.6
        σ[] = change_param(frame; frame_range=(0.4, 0.6), param_range=(0.4, 0.18))
    end
    # Return to normal
    if frame >= 0.7
        μ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.58, 0))
        σ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.18, 0.4))
    end
end

# animation settings
frames = range(0, 1, length=60)
record(make_animation, fig, "rt_normal.gif", frames; framerate=30)

# ExGaussian =====================================================================================

# Parameters
μ = Observable(0.0)
σ = Observable(0.4)
τ = Observable(0.1)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(ExGaussian($μ, $σ, $τ), x))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("ExGaussian(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)), τ = $(round($τ, digits = 2)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
density!(ax, df.RT, npoints=1000, color=:grey)
lines!(x, pdf.(ExGaussian(0.4, 0.06, 0.2), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4, color=:orange)
fig

function make_animation(frame)
    if frame < 0.2
        μ[] = change_param(frame; frame_range=(0, 0.2), param_range=(0, 0.4))
    end
    if frame >= 0.2 && frame < 0.4
        σ[] = change_param(frame; frame_range=(0.2, 0.4), param_range=(0.4, 0.1))
    end
    if frame >= 0.4 && frame < 0.6
        τ[] = change_param(frame; frame_range=(0.4, 0.6), param_range=(0.1, 0.4))
    end
    # Return to normal
    if frame >= 0.7
        μ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.4, 0))
        σ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.1, 0.4))
        τ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.4, 0.1))
    end
end

# animation settings
frames = range(0, 1, length=60)
record(make_animation, fig, "rt_exgaussian.gif", frames; framerate=30)


# ExGaussian 2 =====================================================================================
# Parameters
μ = Observable(0.3)
σ = Observable(0.2)
τ = Observable(0.001)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(ExGaussian($μ, $σ, $τ), x))

m = Observable(mean(rand(ExGaussian(0.3, 0.2, 0.001), 100_000)))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("Wald(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)), τ = $(round($τ, digits = 3)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
lines!(x, y, linewidth=4, color=:orange)
vlines!(m, color=:green, label="Average RT")
leg = axislegend(position=:rt)
fig

function make_animation(frame)
    if frame < 0.5
        τ[] = change_param(frame; frame_range=(0, 0.5), param_range=(0.001, 0.4))
    end
    # Return to normal
    if frame >= 0.5
        τ[] = change_param(frame; frame_range=(0.5, 1), param_range=(0.4, 0.001))
    end
    m[] = mean(rand(ExGaussian(0.3, 0.2, τ[]), 100_000))
end

# animation settings
frames = range(0, 1, length=60)
record(make_animation, fig, "rt_exgaussian2.gif", frames; framerate=30)

# Wald =====================================================================================
# using Turing

# @model function wald_model(x)
#     ν ~ truncated(Normal(0, 1); lower=0)
#     α ~ truncated(Normal(0, 1); lower=0)
#     τ ~ truncated(Normal(0, 1); lower=0)
#     x ~ Wald(ν, α, τ)
# end
# sample(wald_model(df.RT), NUTS(), 400)

# Parameters
ν = Observable(2.0)
α = Observable(1.0)
τ = Observable(0.0)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(Wald($ν, $α, $τ), x))

m = Observable(mean(rand(Wald(2.0, 1.0, 0.0), 100_00)))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("Wald(ν = $(round($ν, digits = 1)), α =  $(round($α, digits = 2)), τ = $(round($τ, digits = 2)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
density!(ax, df.RT, npoints=1000, color=:grey)
# lines!(x, pdf.(Wald(4.03, 1.76, 0.143), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4, color=:orange)
vlines!(m, color=:green, label="Average RT")
leg = axislegend(position=:rt)
fig

function make_animation(frame)
    if frame < 0.1
        τ[] = change_param(frame; frame_range=(0.0, 0.1), param_range=(0.0, 0.4))
    end
    if frame >= 0.1 && frame < 0.2
        τ[] = change_param(frame; frame_range=(0.1, 0.2), param_range=(0.4, 0.143))
    end
    if frame >= 0.25 && frame < 0.35
        α[] = change_param(frame; frame_range=(0.25, 0.35), param_range=(1.0, 2.5))
    end
    if frame >= 0.35 && frame < 0.45
        α[] = change_param(frame; frame_range=(0.35, 0.45), param_range=(2.5, 1.76))
    end
    if frame >= 0.55 && frame < 0.65
        ν[] = change_param(frame; frame_range=(0.55, 0.65), param_range=(2.0, 1.25))
    end
    if frame >= 0.65 && frame < 0.75
        ν[] = change_param(frame; frame_range=(0.65, 0.75), param_range=(1.25, 4.0))
    end
    # Return to normal
    if frame >= 0.8
        ν[] = change_param(frame; frame_range=(0.8, 1), param_range=(4.0, 2.0))
        α[] = change_param(frame; frame_range=(0.8, 1), param_range=(1.76, 1.0))
        τ[] = change_param(frame; frame_range=(0.8, 1), param_range=(0.143, 0.0))
    end
    m[] = mean(rand(Wald(ν[], α[], τ[]), 100_000))
end

# animation settings
frames = range(0, 1, length=120)
record(make_animation, fig, "rt_wald.gif", frames; framerate=30)


# Random Walk =====================================================================================

# Functions
function random_walk(n)
    x = zeros(n)
    for i in 2:n
        x[i] = x[i-1] + rand([-1, 1])
    end
    return x
end

function generate_trace(n, i=1)
    y = random_walk(n)
    x = range(0, 0.7, length=n)
    return DataFrame(x=x, y=y, iteration=i)
end

# Animation settings
n_frames = 240
frames = range(0, 1, length=n_frames)

# Make trace data
df = DataFrame(x=Float64[], y=Float64[], iteration=Int64[])
for i in 1:40
    df = vcat(df, generate_trace(200, i))
end
df.Frame = repeat(frames, inner=Int(ceil(nrow(df) / n_frames)))[1:nrow(df)]

# Find crossing point
df_crossings = DataFrame(y=Float64[], iteration=Int64[], Frame=Float64[])
for iter in unique(df.iteration)
    data = df[df.iteration.==iter, :]
    # Find y when x closest to 0.7
    idx = argmin(abs.(data.x .- 0.7))
    push!(df_crossings, (data.y[idx], iter, data.Frame[idx]))
end

# Density
density_points = Observable([0])
density_alpha = Observable(0)

# Initialize the figure
fig = Figure()
ax1 = Axis(
    fig[1, 1],
    title="Random Walk",
    xlabel="Time",
    # ylabel="Evidence",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false
)
xlims!(ax1, 0, 0.73)
ylims!(ax1, -40, 40)
colsize!(fig.layout, 1, Relative(2 / 3))
hidespines!(ax1, :r)

ax2 = Axis(
    fig[1, 2],
    title="Crossing Distribution",
    # xlabel="Time",
    # ylabel="Evidence",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
    xticklabelsvisible=false
)
ylims!(ax2, -40, 40)
xlims!(ax2; low=0)
hidespines!(ax2, :l)
colgap!(fig.layout, 1, 0.1)


points = Dict()
for iter in unique(df.iteration)
    points["i"*string(iter)] = Observable(Point2f[(0, 0)])
end

for iter in unique(df.iteration)
    lines!(ax1, points["i"*string(iter)], color=cgrad(:viridis, length(unique(df.iteration)); categorical=true, alpha=0.9)[iter])
end
vlines!(ax1, 0.7, color=:red, linewidth=2, linestyle=:dash)
density!(ax2, density_points, npoints=1000, direction=:y,
    color=@lift((:orange, $density_alpha)))
fig

function make_animation(frame)
    # Trace lines
    data = df[df.Frame.==frame, :]
    for row in eachrow(data)
        iter = row.iteration
        new_point = Point2f(row.x, row.y)
        points["i"*string(iter)][] = push!(points["i"*string(iter)][], new_point)
    end

    # Cross points
    cross = df_crossings[df_crossings.Frame.==frame, :]
    if nrow(cross) > 0
        # ax1
        lines!(ax1, [0.7, 0.73], [cross.y[1], cross.y[1]],
            color=cgrad(:viridis, length(unique(df.iteration)); categorical=true, alpha=1)[cross.iteration[1]])
        # ax2
        density_alpha[] = 1
        scatter!(ax2, 0.0, cross.y[1], markersize=20,
            color=cgrad(:viridis, length(unique(df.iteration)); categorical=true, alpha=0.8)[cross.iteration[1]])
        density_points[] = push!(density_points[], cross.y[1])
    end
end

# animation settings
record(make_animation, fig, "rt_randomwalk.gif", frames; framerate=30)



# Walk Generation =====================================================================================


using DataFrames
using SequentialSamplingModels

α = Observable(1.5)
τ = Observable(0.05)
ν = Observable(3.0)

# Initialize the figure
fig = Figure()
ax1 = Axis(
    fig[1, 1],
    title=@lift("Wald(ν = $(round($ν, digits = 1)), α = $(round($α, digits = 1)), τ = $(round($τ, digits = 2)))"),
    # xlabel="Time",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
    xticklabelsvisible=false
)
hidespines!(ax1, :b)
xlims!(ax1; low=0, high=1.5)
ylims!(ax1; low=0, high=3.5)

ax2 = Axis(
    fig[2, 1],
    # title="Density",
    xlabel="Time",
    ylabel="Evidence",
    yticksvisible=false,
    xticksvisible=false,
    # ygridvisible=false,
    # yticklabelsvisible=false,
    # xticklabelsvisible=false
)
hidespines!(ax2, :t)
xlims!(ax2; low=0, high=1.5)
ylims!(ax2; low=-0.5, high=2.5)
rowgap!(fig.layout, 1, 0.1)


# Traces
function make_points(ν=4, α=1.5, τ=0.2, max_time=1500)
    trace = simulate(Wald(ν, α, τ); Δt=0.001)[2]

    x = τ .+ range(0, 0.001 * length(trace), length=length(trace))
    x = collect(x)

    points = [(i, j) for (i, j) in zip(x, trace)]
    return Point2f.(points)
end

for iter in 1:40
    lines!(ax2, @lift(make_points($ν, $α, $τ)),
        color=cgrad(:viridis, 40; categorical=true, alpha=0.8)[iter],
        linewidth=0.5)
end

# Rest
xaxis = range(0, 1.5, length=1000)
lines!(ax1, xaxis, @lift(pdf.(Wald($ν, $α, $τ), xaxis)), color=:orange)
lines!(ax2, @lift([0, $τ]), [0, 0], color=:red, linewidth=2)
lines!(ax2, [0, 1.5], @lift([$α, $α]), color=:red, linestyle=:dash)
lines!(ax2, @lift([$τ, $τ + 1 / 4]), @lift([0, $ν / 4]), color=:black)
lines!(ax2, @lift([$τ, $τ + 1 / 4]), [0, 0], color=:black, linestyle=:dash)



fig


function make_animation(frame)
    if frame < 0.15
        τ[] = change_param(frame; frame_range=(0, 0.15), param_range=(0.05, 0.2))
    end
    if frame >= 0.25 && frame < 0.40
        α[] = change_param(frame; frame_range=(0.25, 0.40), param_range=(1.5, 2.4))
    end
    if frame >= 0.45 && frame < 0.65
        ν[] = change_param(frame; frame_range=(0.45, 0.65), param_range=(3.0, 5.0))
    end
    # Return to normal
    if frame >= 0.7 && frame < 0.85
        α[] = change_param(frame; frame_range=(0.7, 0.85), param_range=(2.4, 1.5))
        τ[] = change_param(frame; frame_range=(0.7, 0.85), param_range=(0.2, 0.05))
        ν[] = change_param(frame; frame_range=(0.7, 0.85), param_range=(5.0, 3.0))
    end
end

# animation settings
frames = range(0, 1, length=90)
record(make_animation, fig, "rt_wald2.gif", frames; framerate=20)



