using CairoMakie, SequentialSamplingModels, Random
using FileIO

img = load("C:/Users/domma/Dropbox/Software/CognitiveModels/content/media/head1.png")

f = Figure(size=(1400, 1000))
ax1 = Axis(f[1, 1],
    aspect=DataAspect(),
    backgroundcolor=:transparent,
    leftspinevisible=false,
    rightspinevisible=false,
    bottomspinevisible=false,
    topspinevisible=false,
    yticksvisible=false,
    xticksvisible=false,
    ygridvisible=false,
    xgridvisible=false,
    yticklabelsvisible=false,
    xticklabelsvisible=false,
)


α = 1
m = DDM(-0.8, α, 0.5, 0.2)

function rescale_x(x)
    return 600 .+ x * 1000
end

function rescale_y(y)
    return 800 .+ y .* 200
end

xaxis = collect(range(0, 1.25, 2000))
ymax = α .+ pdf.(m, 1, xaxis)
ymin = α .+ zeros(length(ymax))
ymax2 = -pdf.(m, 0, xaxis)
ymin2 = zeros(length(ymax2))

band!(rescale_x(xaxis), rescale_y(ymin), rescale_y(ymax),
    color=rescale_x(xaxis), colormap=["#08133c", "#08133c", "#2d4972", "white", "white"])
band!(rescale_x(xaxis), rescale_y(ymin2), rescale_y(ymax2),
    color=rescale_x(xaxis), colormap=["#08133c", "#08133c", "#2d4972", "white", "white"])

col = cgrad(:linear_bmy_10_95_c78_n256, 30; categorical=true, alpha=0.9)
for trace in reverse(1:30)
    x, y = simulate(m; Δt=0.002)
    if maximum(x) > 1
        continue
    end
    x = 0.2 .+ x
    lines!(rescale_x(x), rescale_y(y); linewidth=2, color=col[trace])
end

image!(ax1, rotr90(img))
f
save("C:/Users/domma/Dropbox/Software/CognitiveModels/content/media/cover_image.png", f; px_per_unit=5)