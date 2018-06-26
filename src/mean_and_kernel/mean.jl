import Base: mean, ==, map, AbstractVector
import Base: map

export CustomMean, ZeroMean, ConstantMean, mean

abstract type MeanFunction end
abstract type BaseMeanFunction <: MeanFunction end

eachindex(μ::BaseMeanFunction) = throw(ErrorException("Cannot construct indices for $μ"))
length(::BaseMeanFunction) = Inf

function AbstractVector(μ::MeanFunction)
    @assert isfinite(length(μ))
    return map(μ, DataSet(eachindex(μ)))
end

map(f::MeanFunction, X::BlockData) = BlockVector([map(f, x) for x in blocks(X)])
map(f::MeanFunction, X::AbstractVector{<:ADS}) = map(f, BlockData(X))

"""
    CustomMean <: BaseMeanFunction

A user-defined mean function. `f(x)` should return a scalar for whatever type of `x` this is
intended to work with.
"""
struct CustomMean{T} <: BaseMeanFunction
    f::T
end
@inline (f::CustomMean)(x) = f.f(x)

"""
    ZeroMean <: BaseMeanFunction

Returns zero (of the appropriate type) everywhere.
"""
struct ZeroMean{T<:Real} <: BaseMeanFunction end
@inline (::ZeroMean{T})(x) where T = zero(T)
@inline map(z::ZeroMean{T}, D::DataSet) where T = Zeros{T}(length(D))
==(::ZeroMean, ::ZeroMean) = true

"""
    ConstantMean{T} <: BaseMeanFunction

Returns `c` (of the appropriate type) everywhere.
"""
struct ConstantMean{T<:Real} <: BaseMeanFunction
    c::T
end
@inline (μ::ConstantMean)(x) = μ.c
@inline map(μ::ConstantMean, D::DataSet) = Fill(μ.c, length(D))
==(μ::ConstantMean, μ′::ConstantMean) = μ.c == μ′.c

"""
    EmpiricalMean <: BaseMeanFunction

A finite-dimensional mean function specified by a vector of values `μ`.
"""
struct EmpiricalMean{T<:Real, Tμ<:AbstractVector{T}} <: BaseMeanFunction
    μ::Tμ
    EmpiricalMean(μ::Tμ) where {T<:Real, Tμ<:AbstractVector{T}} = new{T, Tμ}(μ)
end
@inline (μ::EmpiricalMean)(n) = μ.μ[n]
==(μ1::EmpiricalMean, μ2::EmpiricalMean) = μ1.μ == μ2.μ
@inline length(μ::EmpiricalMean) = length(μ.μ)
@inline eachindex(μ::EmpiricalMean) = eachindex(μ.μ)
