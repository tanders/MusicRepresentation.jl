
# TODO: extra file Pitch.jl to import
# TODO: turn into module -- and find a nice name for it :)
# module MusicRepresentation

# TODO: export API

# using BigLib: thing1, thing2

import Base: show, +, -, convert, promote_rule

#=
import Base.show
import Base.+
import Base.-
# import Base.*
# import Base./
import Base.convert
import Base.promote_rule
=#

# TODO: how can individual settings be documented?
""" Global module settings.
"""
const GLOBAL =
    Dict(
    #=
    Sets the pitches per octave for an arbitrary equidistant tuning.
    NB: The term keynum here is not limited to a MIDI keynumber, but denotes a keynumber in any equidistant tuning. For instance, if pitches_per_octave=1200 then `keynum` denotes cent values.
    =#
        :pitches_per_octave => 31,
        :dummy => "bla")
# GLOBAL[:pitches_per_octave]


###############################################################################
#
# Plain frequency (ratio) processing and their relation to equal temeraments
#

""" Freq at MIDI keynum 0 so that keynum 69 ≈ 440 Hz
"""
const freq₀ = 8.175798915643710

"""
    keynum_to_freq(keynum::Int[, ppo=GLOBAL[:pitches_per_octave]::Int])

Transform a `keynum` into the corresponding frequency in an equally tempered scale with `ppo` pitches per octave. The function is 'tuned' such that `keynum_to_freq(69, 12)` returns 440.0 (Hz).

# Examples
```jldoctest
julia> keynum_to_freq(69, 12) ≈ 440.0
true
```
"""
keynum_to_freq(keynum::Int, ppo=GLOBAL[:pitches_per_octave]::Int) =
    2 ^ (keynum / ppo) * freq₀


"""
    freq_to_keynum_real(freq::Real[, ppo=GLOBAL[:pitches_per_octave]::Int])::Real

Variant of [`freq_to_keynum`](@ref) not rounding the result.

# Examples
```jldoctest
julia> freq_to_keynum_real(440.0, 12) ≈ 69
true
```
"""
freq_to_keynum_real(freq::Real, ppo=GLOBAL[:pitches_per_octave]::Int)::Real =
    log2((freq / freq₀)) * ppo

"""
    freq_to_keynum(freq::Real[, ppo=GLOBAL[:pitches_per_octave]::Int])::Int

Transform `freq` into the corresponding key number in an equally tempered scale with  `ppo` pitches per octave. The function is 'tuned' such that freq_to_keynum(440.0, 12) returns 69.
NB: The term keynum here is not limited to a MIDI keynumber, but denotes a keynumber in any equidistant tuning. For instance, if `ppo==1200` then `keynum` denotes cent values.

# Examples
```jldoctest
julia> freq_to_keynum(440.0, 12)
69
```

See also [`freq_to_keynum_real`](@ref)
"""
freq_to_keynum(freq::Real, ppo=GLOBAL[:pitches_per_octave]::Int)::Int =
    Integer(round(freq_to_keynum_real(freq, ppo)))


"""
    ratio_to_keynum(ratio::Real, ppo=GLOBAL[:pitches_per_octave]::Int)::Int

Transform a frequency `ratio` into the corresponding keynumber interval depending on the given pitches per octave.
"""
ratio_to_keynum(ratio::Real, ppo=GLOBAL[:pitches_per_octave]::Int)::Int =
    freq_to_keynum(ratio*freq₀, ppo)

ratio_to_keynum_real(ratio::Real, ppo=GLOBAL[:pitches_per_octave]::Int) =
    freq_to_keynum_real(ratio*freq₀, ppo)

ratio_to_keynum(d::Dict{String, T}, ppo) where {T<:Rational} =
    Dict(name => ratio_to_keynum(ratio, pitches_per_octave) for (name, ratio) in d)



"""
    ratio_to_cent(ratio::Real)::Real

Transform a frequency `ratio` into the corresponding cent measurement.

# Examples
```jldoctest
julia> ratio_to_cent(3//2) ≈ 701.95
true
```
"""
ratio_to_cent(ratio::Real) =
    freq_to_keynum_real(ratio*freq₀, 1200)




#=
"""

Transform `ratio` into a pitch class interval depending on the given pitches per octave.
"""
ratio_to_pitchclass(ratio::real, ppo=GLOBAL[:pitches_per_octave]::Int
                    temperament, min_occurrences)::Int =
    keynum_to_freq()
=#


"""
    ji_pitchclass(x::Real)::Rational

Transforms the frequency ratio x into the interval [1, 2) to represent a corresponding pitch class expressed as a fraction.

# Examples
```jldoctest
julia> ji_pitchclass(9//4)
9//8

julia> ji_pitchclass(2//9)
16//8

julia> ji_pitchclass(3//2)
3//2

julia> ji_pitchclass(3)
3//2
```
"""
function ji_pitchclass(x::Real)::Rational
    if x >= 2
        octaves = Integer(floor(log2(x)))
        x * 1//(2^octaves)
    elseif x < 1
        octaves = abs(Integer(floor(log2(x))))
        x * (2^octaves)//1
    else
        x
    end
end

"""
    ji_pitchclass(x::Dict{String, Rational})

Applies `ji_pitchclass` to every value in dict.
"""
ji_pitchclass(d::Dict{String, T}) where {T <: Rational} =
    Dict(name => ji_pitchclass(ratio) for (name, ratio) in d)


"""
    keynum_to_pitchclass(keynum::Integer, ppo=GLOBAL[:pitches_per_octave]::Int)::Int

Transform `keynum` in an equally tempered scale with `ppo` pitches into its corresponding pitchclass in [0, PitchesPerOctave).

# Examples
```jldoctest
julia> keynum_to_pitchclass(61, 12)
1
```
"""
keynum_to_pitchclass(keynum::Integer, ppo=GLOBAL[:pitches_per_octave]::Int)::Int =
    mod(keynum, ppo)



###############################################################################
#
# Regular temperaments
#


# TODO: revise: if generators are given as fractions, the resulting temperament can also be fractions -- that would be useful.
# TODO: revise: instead of returning a vector of integers, why not return a vector of floats always measured in cent?
"""

Return sorted vector of pitch classes (integers) that constitute a regular temperament, i.e. a temperament whose pitches are generated by a repeated transposition with the same interval(s) (http://en.wikipedia.org/wiki/Regular_temperament).

# Arguments

`generators` is the list of transposition intervals; their unit of measurement depends on `ppo` (e.g., if pitches per octave is the default 1200, then `generators` and all tempered pitches are measured in cent). The octave interval is always implicitly added as generator to a regular temperament (i.e., generated pitches that "fell outside" the octave are automatically "folded back" into the octave).

`generator_factors` is a specification that denotes the generator transpositions. For each element in generator, generator_factors contains a tuple of integers `(min_tranposition, max_transposition)`. For example, the generator factor (1 2) indicates that the corresponding generator is transposed 1 time downwards and 2 times upwards (i.e., together with the start pitch, four pitches are generated in total).

`ppo`: denotes the pitches per octave and thus the unit of measurement for `generators` and the resulting pitch classes of the temperament.

# TODO: revise doc of this arg.
`generator_factors_offset` is intended to avoid negative generator factors, in case generator factors are variables (e.g., if using the class HS.score.regularTemperamentMixinForNote). For example, if generatorFactorsOffset is 100, then the generator factors spec (99 102) indicates that the corresponding generator is transposed 1 time downwards and 2 times upwards.

`transposition` is a pitch class interval for transposing the whole temperament. With the default value 0, the temperament's "origin" is the pitch class 0 (always C).

See examples/RegularTemperaments.oz for usage examples.

# Examples

TODO: revise
[5-limit just intonation](https://en.wikipedia.org/wiki/Just_intonation#Five-limit_tuning). The generators `3//2` and `5//4` . The pitch class for the note C is always 0 (1//1?). The example generates 6 fifths from C downwards (i.e. up to G♭) and 6 fifths upwards (i.e. up to F♯). In addition, from each tone in the chain of fifths it generates a major third up and down. So, it returns 13*3 = 39 pitches in total.
```jldoctest
julia> make_regular_temperament([3//2, 5//4], [(-6, 6), (-1, 1)])
TODO
```

5-limit just intonation. The generators are 3/2 and 5/4 (measured in cent). The pitch class for the note C is always 0. The example generates 6 fifths from C downwards (i.e. up to G♭) and 6 fifths upwards (i.e. up to F♯). In addition, from each tone in the chain of fifths it generates a major third up and down. So, it returns 13*3 = 39 pitches in total.
```jldoctest
julia> make_regular_temperament([702, 386], [(-6, 6), (-1, 1)])
TODO
```

12-TET: starting from 0 (C) generate 12 semitones of 100 cent each.
```jldoctest
julia> make_regular_temperament([100], [(0, 11)])
TODO
```

TODO: revise
A chain of 14 fifths of [1/4-comma meantone](https://en.wikipedia.org/wiki/Meantone_temperament) ```jldoctest
julia> make_regular_temperament([696.59], [(-6, 7)])
TODO

TODO: revise
A chain of 14 fifths of [Helmholtz temperament](https://en.wikipedia.org/wiki/Schismatic_temperament)
```jldoctest
julia> make_regular_temperament([701.71], [(-6, 7)])
TODO
```
"""
#=
%% TODO:
%% - optionally, show the generators and generatorFactors that generated a certain pitch class. E.g., instead of a list of ints return list of records unit(pc:PC generator:Generator factor:Factor) (useful, e.g. for temperament debugging)
%% - ?? optionally remove any pitch classes that are only unisonInterval apart (i.e. which are considered equivalent). Problems:
%%   - which of the close PCs to select.
%%   - regular constraints then do not work for all generatorFactors anymore -- so better don't remove any PCs
%%  -> If I need something like this, then it could be an extra function.
=#
# TODO: port from Oz incomplete
function make_regular_temperament(generators::Vector{T1}, generator_factors::Vector{Tuple{T2, T2}}
# function make_regular_temperament(generators::Vector{Real}, generator_factors::Vector{Tuple{Integer, Integer}}
    # ; generator_factors_offset=0, transposition=0::Integer, ppo=1200::Int
    ) where {T1 <: Real, T2 <: Integer}
    if size(generators) != size(generator_factors)
        error(ArgumentError("Length of `generators` and `generator_factors` must match: $generators, $generator_factors"))
    end
    # TODO: unfinished
    factorss = [min:max for (min, max) in generator_factors]
    return factorss
end

#TMP
#=
make_regular_temperament([702, 386], [(-6, 6), (-1, 1)])

make_regular_temperament([3//2, 5//4], [(-6, 6), (-1, 1)])


Array{Real, 1} >: Array{Int64, 1}

typeof([(-6, 6), (-1, 1)])

make_regular_temperament([696.59], [(-6, 7)])


=#

# TMP
#=
f(x::Vector{T}) where {T <: Real} = size(x)

f(x::Vector{Real}) = size(x)
f([1, 2, 3])
=#

#=
struct RegularTemperament
    _::T
end
=#

###############################################################################
#
# Pitch type definitions
#

abstract type AbstractPitch end


# TODO: make part of doc
# !! Approach: the type stores internally some abstract information, like an underlying ratio, and the types' API (methods) then transform this information into concrete pitches in an equal temperament depending on pitches_per_octave.
# Internally store fraction (or float) as a pitch representation, which is then with the API always automatically translated into an equal temperament integer.

struct PitchClass{T<:Rational} <: AbstractPitch
    _::T
    PitchClass{T}(x) where {T<:Rational} = new(ji_pitchclass(x))
end
PitchClass(x::T) where {T<:Rational} = PitchClass{T}(x);
PitchClass(x::Real) = PitchClass(convert(Rational, x));
# PitchClass(1.25)

# TODO: refine by introducing symbolic pitch notation for current ET
# show note name, depending on et() and pitches_per_octave
show(io::IO, p::PitchClass) = print(io, "PitchClass($(p._))")


struct PitchInterval{T<:Rational} <: AbstractPitch
    _::T
end

# TODO: refine by introducing symbolic pitch notation for current ET
# show note name, depending on et() and pitches_per_octave
show(io::IO, p::PitchInterval) = print(io, "PitchInterval($(p._))")

# !! TODO: should a Pitch be a composite data structure consisting of a PitchClass and an Octave?
struct Pitch{T<:Rational} <: AbstractPitch
    _::T
end



# Methods for arbitrary type combinations
+(x::AbstractPitch, y::AbstractPitch) = +(promote(x,y)...)
-(x::AbstractPitch, y::AbstractPitch) = -(promote(x,y)...)

# Methods for twice the same type
+(p1::T, p2::T) where {T<:AbstractPitch} = T(p1._ * p2._)
-(p1::T, p2::T) where {T<:AbstractPitch} = T(p1._ / p2._)

# Methods combining with numbers
# ? TODO: define also inverse
+(p1::T, p2::Rational) where {T<:AbstractPitch} = T(p1._ * p2)
-(p1::T, p2::Rational) where {T<:AbstractPitch} = T(p1._ / p2)

# TODO: should be inverse and not neg.
-(p1::T) where {T<:AbstractPitch} = T(p1._.den // p1._.num)



convert(::Type{PitchClass{T}}, x::PitchInterval) where {T<:Rational} =
    PitchClass{T}(x._)
# ?? convert(::Type{PitchInterval}, x::PitchClass) = PitchInterval(x._)

promote_rule(::Type{PitchClass{T}}, ::Type{PitchInterval{S}}) where {T<:Rational, S<:Rational} =
    PitchClass{promote_type(T, S)}



"""
    et(p::AbstractPitch, ppo=GLOBAL[:pitches_per_octave]::Int)::Int

The key-number, pitch interval, or pitch class integer in the given equal
temperament.
"""
et(p::PitchClass, ppo=GLOBAL[:pitches_per_octave]::Int)::Int =
    ratio_to_keynum(p._, ppo)

et(p::PitchInterval, ppo=GLOBAL[:pitches_per_octave]::Int)::Int =
    ratio_to_keynum(p._, ppo)

#= TODO: also depends on octave ?
et(p::Pitch, ppo=GLOBAL[:pitches_per_octave]::Int)::Int =
    freq_to_keynum(p._, ppo)
=#


#=
et(C)
et(C+fifth+♯)
et(♯)
=#



###############################################################################
#
# Pitch classes and accidentals
#

# Code generation and execution with eval, but no macro
"""
    def_pitch_intervals(intervals::Dict{String, T} where {T <: Rational})

Declare constants for a range of pitch intervals given in a dictionary by pairs of names (strings) and rationals.

NOTE: This is a code-generation function that defines global bindings.

# Examples
```julia-repl
julia> def_pitch_intervals()
```
"""
# TODO: consider adding all intervals to global dict for printing interval names
function def_pitch_intervals(intervals::Dict{String, T} where {T <: Rational})
    for (acc_name, acc_val) in intervals
        # bind global constant
        eval(:(const $(Symbol(acc_name)) = $(PitchInterval(acc_val))))
    end
end

# ? TODO: Reconsider: is this the right approach?
pitchintervals = Dict(
    "fifth" => 3//2,
    "fourth" => 4//3,
    "major_third" => 5//4,
    "minor_third" => 6//5,
    "major_sixth" => 5//3,
    "minor_sixth" => 8//5,
    # major tone
    "major_second" => 9//8,
    # diatonic semitone
    "minor_second" => 16//15,
    "major_seventh" => 15//8,
    "minor_seventh" => 16//9,
    #
    "harmonic_seventh" => 7//4
    )

#=
9//8 * 5//4

ratio_to_keynum(45//32, 12)



2//1 / 9//8
=#


# TODO: documentation
# TODO: Define type Accidental, where both PitchInterval and accidental are subtypes of AbstractPitchInterval?
# 7 fifths above/below
# const ♯ = PitchInterval(ji_pitchclass((3//2) ^ 7))
# const ♭ = -♯
# TODO: define various microtonal accidentals


# TODO: add more common intervals
const fifth = PitchInterval(3//2)

# NOTE: required value of nominals depends also on intended tuning.
# E.g., for meantone, E should be 5//4 instead of 81//64
# So, whole representation based on Pythagorean intervals as backbone does not work
#
# If at some stage I want support for dynamic temperament, I need some representation that can be shared across temperaments
# Perhaps some kind of abstract position in a regular temperament, as long as the temerament is generated from (different tunings of) the same interval(s)
# TODO: Consider more abstract representation than fractions, e.g., monzos (http://www.tonalsoft.com/enc/m/monzo.aspx) ... or if suitable perhaps vals,
ji_nominals = ji_pitchclass(Dict(
    "F"=>1//1 / 3//2,
    "C" => 1//1,
    "G"=>3//2,
    "D"=>(3//2) ^ 2,
    "A"=>(3//2) ^ 3,
    "E"=>(3//2) ^ 4,
    "B"=>(3//2) ^ 5
    ))


# def_pitch_intervals(ji_nominals)


# NOTE: math seemingly wrong!
const C = PitchClass(1//1)
const F = C - fifth
const G = C + fifth
const D = G + fifth
const A = D + fifth
const E = A + fifth
const B = E + fifth


#=
# BUG: in 31-TET this should be 2
# Perhaps ratio not correctly defined?? It is Pythagorean sharp, but for 31-ET I might need something different?
# See intervals in https://en.wikipedia.org/wiki/31_equal_temperament#Interval_size
# NOTE: there is a difference between chromatic and diatonic semitone, and it is not tempered out in 31-TET
# TODO: Perhaps I want to import accidentals depending on temperaments from submodules
et(♯)

et(C)
et(D)
=#


# ♭ test
#=
F == B+♭ + fifth
=#

# testing at REPL
# [F, C, G, D, A, E, B]

#=
# TODO: change defs for Pitch classes below (A, B, C ...) using PitchClass and fractions
C = Pitch(0)
A = Pitch(mod(freq_to_keynum(440.0), pitches_per_octave))
#=
F = C / 3//2
G = C * 3//2
D = G * 3//2
A = D * 3//2
E = A * 3//2
B = E * 3//2
=#
=#


#=
# TODO: tests

# BUG: wrong approach here, need a different function, or need to transpose ♯ relative to pitch₀ ?
# I need an et() variant where et(1//1) == 0
et(♯)

F+♯



C+♯

=#





###################
#
# Old, just left as template -- kann spaeter weg


#=

#=
Pitch representation is about representing notated pitches -- tuning systems should be independent of that (and ideally it should be possible to change that "on the fly")

TODO: Difficulty with JI: unlimited pitch space. I don't want to have that as a default (only as user-defined a special case).
Therefore simplification as default for notated score: support arbitrary equal temperaments, represented as integers. I can then have an arbitrarily high resolution for complex JI tunings for notation, but the space is never unlimited, but as unlimited as one wants. By rounding all intervals (incl. accidentals) to integers I avoid commas if I want to, but can also rather freely introduce them with a high value for pitches_per_octave. Every pitch integer in the equal-tempered space has a clear name (incl. possibly enharmonic variants), so I can easily deduce pitch names to show with Base.print

=#

# TODO: Problem: with pure pitch ratios I cannot even have a proper major scale.
# I think I need compromise of temperament, at least as an option from the beginning
# Tricky: for JI I need multiplication of ratios, for temperament I need addition of pitch classes etc.
# I would be able to translate all JI pitches into pitch classes etc., but then they are not as clean as the fractions of the frequency ratios anymore.

# TODO: ensure in constructor that ratio is in [1, 2)
struct PitchRatio
    ratio::Rational
end

# TODO: should PitchRatio and Accidental have a common supertype
# TODO: For temperaments I want to have Accidentals that are `additional`, not `multiplicative`, so there should be different types for either concept
# TODO: ensure in constructor that ratio is in [1, 2)
struct Accidental
    ratio::Rational
end

const ♯ = Accidental((3//2) ^ 7) # 7 fifths above
const ♭ = Accidental((2//3) ^ 7)

*(p::PitchRatio, f::Rational) = PitchRatio(p.ratio * f)
/(p::PitchRatio, f::Rational) = PitchRatio(p.ratio / f)

# TODO: some more generic solution
*(p::PitchRatio, f::Accidental) = PitchRatio(p.ratio * f.ratio)
/(p::PitchRatio, f::Accidental) = PitchRatio(p.ratio / f.ratio)


# TODO: 1//1 should not necessarily be fixed on C – how can I generalise that?
const C = PitchRatio(1//1)
const F = C / 3//2
const G = C * 3//2
const D = G * 3//2
const A = D * 3//2
const E = A * 3//2
const B = E * 3//2

F*♯

# ♭ test
F == B*♭ * 3//2


=#

# end
