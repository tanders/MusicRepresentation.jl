
# TODO: extra file Pitch.jl to import
module MusicRepresentation
# using BigLib: thing1, thing2

import Base.show
import Base.*
import Base./
# import Base.convert

# const root = 1//1

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



end
