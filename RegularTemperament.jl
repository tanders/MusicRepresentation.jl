
# Doc: http://juliamath.github.io/Primes.jl/stable/api.html
import Primes


#= # old
# vals
# TODO: compute this values automatically
# TODO: check term seed
et12_generator = 2 ^ (1/12)
et12_val = [12, 19, 28]

et12_generator ^ 19

generator ^ x = ratio
x = log(ratio, generator)
=#




"""
    ratio_to_monzo(ratio::Rational{Integer}, limit::Integer=2)

Generate a monzo from a given `ratio`.

A monzo represents a just intonation pitch or interval ratio as a vector of prime exponents. This format makes explicit the composition of complex pitches/intervals out of simple intervals (see examples below). For more details on monzos see the respective [Tonalsoft Encyclopedia entry](http://www.tonalsoft.com/enc/m/monzo.aspx).

# Examples

The monzo for a perfect fifth: one octave down (2^-1) and one undecime up (3^1).
```jldoctest
julia> ratio_to_monzo(3//2)
[-1, 1]
```

A minor third.
```jldoctest
julia> ratio_to_monzo(6//5)
[1, 1, -1]
```

The syntonic comma, 81/80:
```jldoctest
julia> ratio_to_monzo(81//80)
[-4, 4, -1]
```
"""
function ratio_to_monzo(ratio::Rational{T}, limit::Integer=2) where {T <: Integer}
    # numerator
    pos = Primes.factor(Dict, ratio.num)
    # denominator (turn into neg exponents)
    neg = Dict((prime => -expt) for (prime, expt) in Primes.factor(ratio.den))
    all = merge(pos, neg)
    max_prime = max(maximum(all)[1], limit)
    primes = Primes.primes(max_prime)
    [get(all, prime, 0) for prime in primes]
end


"""
    _pad_monzo(monzo::Vector{T}, size::Integer) where {T <: Real}

Pads `size` 0s at the end of `monzo`. This does not change its value, but it can be necessary to ensure two monzos have the same length.

```jldoctest
julia> _pad_monzo([1, 2], 2)
[1, 2, 0, 0]
```
"""
function _pad_monzo(monzo::Vector{T}, size::Integer) where {T <: Real}
    for _ in 1:size
        push!(monzo, 0)
    end
    return monzo
end


# TODO: def function that automatically pads one of two monzos so that they have the same length



# TODO: finish def: currently all given monzo's must have same length
"""
    transpose_monzo(monzos::Vector{T}...) where {T <: Real}

Trasposes given monzos by each other (pair-wise addition of their prime exponents).

Transpose a fifth by a major third down, resulting in a minor third.
```jldoctest
julia> transpose_monzo([1, 1, -1])
6//5
```
"""
transpose_monzo(monzos::Vector{T}...) where {T <: Real} =
    +(monzos...)





# TODO: Revise function name: There are also rational monzos, which would perhaps better translate to floats (likely even automatically)
# TODO: finish doc
"""

Transform a ratio into a

A minor third.
```jldoctest
julia> monzo_to_ratio([1, 1, -1])
6//5
```

TODO:
A quarter-comma meantone fifth.
```jldoctest
julia> monzo_to_ratio([-1, 1,])
6//5
```

"""
function monzo_to_ratio(monzo::Vector{T}) where {T <: Real}
    # TODO: needs generalising, for arbitrary length of xs
    #   primes = Primes.primes(limit)
    primes = [2//1, 3//1, 5//1]
    # Factor of all elements
    prod(primes .^ monzo)
end

#=
monzo_to_ratio(unison)
monzo_to_ratio(fifth)
monzo_to_ratio(pyth_maj_third)
monzo_to_ratio(just_maj_third)
monzo_to_ratio(syntonic_comma)

# currently wrong
monzo_to_ratio(quarter_comma_meantone_fifth)


syntonic_comma_ratio = monzo_to_ratio(syntonic_comma)
Primes.factor(syntonic_comma_ratio.num)
Primes.factor(syntonic_comma_ratio.den)

=#


"""
    make_edo_val(et::Integer, limit::Integer=5)

Generate a val for an equal temperament with `edo` steps per octave considering prime numbers up to the given prime `limit`.

Vals are useful for mapping JI ratios (or monzos) into other temperaments. For more details on vals see the respective [Tonalsoft Encyclopedia entry](http://www.tonalsoft.com/enc/v/val.aspx).

# Examples

The 2,3,5-val for 12-EDO.
```jldoctest
julia> make_edo_val(12)
[12, 19, 28]
```
"""
function make_edo_val(edo::Integer, limit::Integer=5)
    primes = Primes.primes(limit)
    et_generator = 2 ^ (1/edo)
    [Integer(round(log(et_generator, prime))) for prime in primes]
end



"""

Compute the size of the interval defined by the `monzo` in steps in the temperament defined by the `val`.
"""
# TODO: revise function name, its too long
# TODO: finish doc
monzo_to_temperament_interval(monzo::Vector{T}, val::Vector{S}) where {T<:Real, S<:Integer} =
    sum(monzo .* val)

#=
et12_val = make_edo_val(12)

monzo_to_temperament_interval(unison, et12_val)
monzo_to_temperament_interval(fifth, et12_val)
monzo_to_temperament_interval(pyth_maj_third, et12_val)
monzo_to_temperament_interval(just_maj_third, et12_val)
# The comma vanishes :)
monzo_to_temperament_interval(syntonic_comma, et12_val)

et31_val = make_edo_val(31)

monzo_to_temperament_interval(unison, et31_val)
monzo_to_temperament_interval(fifth, et31_val)
monzo_to_temperament_interval(pyth_maj_third, et31_val)
monzo_to_temperament_interval(just_maj_third, et31_val)
# The comma vanishes :)
monzo_to_temperament_interval(syntonic_comma, et31_val)



et22_val = make_edo_val(22)

monzo_to_temperament_interval(unison, et22_val)
monzo_to_temperament_interval(fifth, et22_val)
monzo_to_temperament_interval(pyth_maj_third, et22_val)
monzo_to_temperament_interval(just_maj_third, et22_val)
# The comma does not vanish for 22-EDO
monzo_to_temperament_interval(syntonic_comma, et22_val)

et22_val = make_edo_val(22, 7)

# Instead, the septimal comma of 64/63 is tempered out
monzo_to_temperament_interval(ratio_to_monzo(64//63), et22_val)


=#


#



# monzos [2^n0, 3^n1, 5^n2, ...]
# TODO: add

# TODO: replace with (partly) automatic definitions (if at all necessary)
unison = [0, 0, 0]
fifth = [-1, 1, 0]
pyth_maj_third = [-6, 4, 0]
just_maj_third = [-2, 0, 1]
syntonic_comma = [-4, 4, -1]

# NOTE: not correct, but demonstrates that exponents can be rational
quarter_comma_meantone_fifth = [-1, 1, -1//4]

# factor(xs::Vector{T}) where {T <: Real} = reduce(*, xs)
