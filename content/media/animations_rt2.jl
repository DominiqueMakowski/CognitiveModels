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
function make_points(ν=4, α=1.5, τ=0.2)
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


# DDM =====================================================================================

Random.seed!(123)

ν = Observable(1.0)
α = Observable(1.0)
τ = Observable(0.05)
z = Observable(0.5)
# yorigin = z[] * α[]

function make_points(ν, α, z, τ)
    x, y = simulate(DDM(ν, α, z, τ); Δt=0.001)

    x = τ .+ x

    points = [(i, j) for (i, j) in zip(x, y)]
    return Point2f.(points)
end

# Initialize the figure
fig = Figure()
ax1 = Axis(
    fig[1, 1],
    title=@lift("Drift Diffusion Model (ν = $(round($ν, digits = 1)), α = $(round($α, digits = 1)), z = $(round($z, digits = 1)), τ = $(round($τ, digits = 2)))"),
    xlabel="Time",
    ylabel="Evidence",
    yticksvisible=false,
    xticksvisible=false,
)

for iter in 1:10
    lines!(ax1, @lift(make_points($ν, $α, $z, $τ)), color=(:black, 0.5))
end



x = range(-0.1, 1.1, length=1000)

lines!(ax1, x, @lift($α .+ pdf.(DDM($ν, $α, $z, $τ), 1, x)), color=:green)
lines!(ax1, x, @lift(-pdf.(DDM($ν, $α, $z, $τ), 0, x)), color=:red)

fig

# Bounds
hlines!(ax1, @lift([$α]), color=:green, linestyle=:dash, label="Correct")
hlines!(ax1, [0], color=:red, linestyle=:dash, label="Incorrect")

# Slope
lines!(ax1, @lift([$τ, $τ + 1 / 6]), @lift([$z * $α, $z * $α + $ν / 6]); color=:orange, linewidth=4)

# Starting
scatter!(ax1, @lift([0, $τ]), @lift([$z * $α, $z * $α]), color=:purple, markersize=10)
lines!(ax1, @lift([0, $τ]), @lift([$z * $α, $z * $α]), color=:purple)
axislegend("Answer"; position=:rt)

function make_animation(frame)
    if frame < 0.1
        τ[] = change_param(frame; frame_range=(0, 0.1), param_range=(0.05, 0.2))
    end
    if frame >= 0.2 && frame < 0.3
        α[] = change_param(frame; frame_range=(0.2, 0.3), param_range=(1, 2))
    end
    if frame >= 0.4 && frame < 0.5
        ν[] = change_param(frame; frame_range=(0.4, 0.5), param_range=(1, 4))
    end
    if frame >= 0.6 && frame < 0.70
        z[] = change_param(frame; frame_range=(0.6, 0.70), param_range=(0.5, 0.1))
    end
    # Return to normal
    if frame >= 0.8 && frame < 0.85
        τ[] = change_param(frame; frame_range=(0.8, 0.85), param_range=(0.2, 0.05))
        α[] = change_param(frame; frame_range=(0.8, 0.85), param_range=(2, 1))
        ν[] = change_param(frame; frame_range=(0.8, 0.85), param_range=(4, 1))
        z[] = change_param(frame; frame_range=(0.8, 0.85), param_range=(0.1, 0.5))
    end
end

# animation settings
frames = range(0, 1, length=120)
record(make_animation, fig, "rt_ddm.gif", frames; framerate=15)