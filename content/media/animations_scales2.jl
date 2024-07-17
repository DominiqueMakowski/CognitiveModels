using CSV
using DataFrames
using Distributions
using SequentialSamplingModels
using GLMakie
using Downloads
using Random
using Turing

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


# OrderedBeta =======================================================================================


import Distributions: ContinuousUnivariateDistribution, Beta, logpdf, pdf, cdf, quantile, sampler
import StatsFuns: logistic, logit, log1pexp
import SpecialFunctions: logbeta
import Random

logit(0.5)


"""
    OrderedBeta(μ, ϕ, k1, k2)

Ordered Beta distribution with parameters:
- `μ`: location parameter [0, 1]
- `ϕ`: precision parameter (must be positive)
- `k1`: first cutpoint
- `k2`: log of the difference between the second and first cutpoints

The distribution is defined on the interval [0, 1] with additional point masses at 0 and 1.
"""
struct OrderedBeta{T<:Real} <: ContinuousUnivariateDistribution
    μ::T
    ϕ::T
    k1::T
    k2::T
    beta_dist::Beta{T}

    function OrderedBeta{T}(μ::T, ϕ::T, k1::T, k2::T) where {T<:Real}
        @assert ϕ > 0 "ϕ must be positive"
        @assert k1 < k2 "k1 must be less than k2"
        new{T}(μ, ϕ, k1, k2, Beta(μ * ϕ, (1 - μ) * ϕ))
    end
end

OrderedBeta(μ::T, ϕ::T, k1::T, k2::T) where {T<:Real} = OrderedBeta{T}(μ, ϕ, k1, k2)

function OrderedBeta(μ::Real, ϕ::Real, k1::Real, k2::Real)
    T = promote_type(typeof(μ), typeof(ϕ), typeof(k1), typeof(k2))
    OrderedBeta(T(μ), T(ϕ), T(k1), T(k2))
end


# Methods ------------------------------------------------------------------------------------------
params(d::OrderedBeta) = (d.μ, d.ϕ, d.k1, d.k2)
minimum(::OrderedBeta) = 0
maximum(::OrderedBeta) = 1
insupport(::OrderedBeta, x::Real) = 0 ≤ x ≤ 1

function logpdf(d::OrderedBeta, x::Real)
    μ, ϕ, k1, k2 = params(d)
    μ_logit = logit(μ)
    thresh = [k1, k1 + exp(k2)]

    if x == 0
        # Stan: log1m_inv_logit(mu_logit - thresh[1])
        return log(1 - logistic(μ_logit - thresh[1]))
    elseif x == 1
        # Stan: log_inv_logit(mu_logit  - thresh[2])
        return log(logistic(μ_logit - thresh[2]))
    elseif 0 < x < 1
        # Stan: log(inv_logit(mu_logit  - thresh[1]) - inv_logit(mu_logit - thresh[2]))
        log_p_middle = log(logistic(μ_logit - thresh[1]) - logistic(μ_logit - thresh[2]))
        # Stan: + beta_proportion_lpdf(y|mu,phi)
        return log_p_middle + logpdf(Beta(μ * ϕ, (1 - μ) * ϕ), x)
    else
        return -Inf
    end
end

pdf(d::OrderedBeta, x::Real) = exp(logpdf(d, x))
loglikelihood(d::OrderedBeta, x::Real) = logpdf(d, x)

# function Random.rand(rng::Random.AbstractRNG, d::OrderedBeta)
#     μ, ϕ, k1, k2 = params(d)
#     thresh = [k1, k1 + exp(k2)]
#     u = Random.rand(rng)

#     if u <= 1 - logistic(μ - thresh[1])
#         return zero(μ)
#     elseif u >= 1 - logistic(μ - thresh[2])
#         return one(μ)
#     else
#         return Random.rand(rng, d.beta_dist)
#     end
# end

# Random.rand(d::OrderedBeta) = rand(Random.GLOBAL_RNG, d)
# Random.rand(rng::Random.AbstractRNG, d::OrderedBeta, n::Int) = [rand(rng, d) for _ in 1:n]
# Random.rand(d::OrderedBeta, n::Int) = rand(Random.GLOBAL_RNG, d, n)

# sampler(d::OrderedBeta) = d

# function cdf(d::OrderedBeta, x::Real)
#     μ, ϕ, k1, k2 = params(d)
#     thresh = [k1, k1 + exp(k2)]

#     if x <= 0
#         return zero(μ)
#     elseif x >= 1
#         return one(μ)
#     else
#         p_0 = 1 - logistic(μ - thresh[1])
#         p_middle = logistic(μ - thresh[1]) - logistic(μ - thresh[2])
#         return p_0 + p_middle * cdf(d.beta_dist, x)
#     end
# end

# function quantile(d::OrderedBeta, q::Real)
#     0 <= q <= 1 || throw(DomainError(q, "quantile must be in [0, 1]"))
#     μ, ϕ, k1, k2 = params(d)
#     thresh = [k1, k1 + exp(k2)]

#     p_0 = 1 - logistic(μ - thresh[1])
#     p_1 = logistic(μ - thresh[2])

#     if q <= p_0
#         return zero(μ)
#     elseif q >= 1 - p_1
#         return one(μ)
#     else
#         p_middle = logistic(μ - thresh[1]) - logistic(μ - thresh[2])
#         q_adjusted = (q - p_0) / p_middle
#         return quantile(d.beta_dist, q_adjusted)
#     end
# end

# mean(d::OrderedBeta) = logistic(d.μ)
# var(d::OrderedBeta) = logistic(d.μ) * (1 - logistic(d.μ)) / (1 + d.ϕ)


# Simulation =======================================================================================
using GLMakie

xaxis = range(0, 1, length=1000)
fig = lines(xaxis, pdf.(OrderedBeta(0.5, 10, 0, 0), xaxis); color=:yellow)
lines!(xaxis, pdf.(OrderedBeta(0.5, 10, 0.7, 1), xaxis); color=:orange)
lines!(xaxis, pdf.(OrderedBeta(0.5, 10, 0.5, 1), xaxis); color=:red)
lines!(xaxis, pdf.(OrderedBeta(0.5, 10, 0.2, 1), xaxis); color=:purple)
lines!(xaxis, pdf.(OrderedBeta(0.5, 10, 0.0, 1), xaxis); color=:blue)
fig