
import Base.convert

#=
Music events represented by tuples of its parameter, which can be incomplete.
That would be only slight syntactic overhead compared to OMN (parenthesis
around every event/note) and it would greatly simplify parsing etc.

Consider adding methods to buildin function convert to convert between different
parameter representations. Problemchen: this is highly domain specific, and
should only be valid within my module, not globally. For only specific symbols
(e.g., for specific pitches) it would be save.

See also style guide section "Avoid type piracy"
https://docs.julialang.org/en/v1/manual/style-guide/#Avoid-type-piracy-1

A clean solution would be to use special times for pitches, note durations,
dynamics and articulations etc., but how can I do that with a very lean syntax?

On using operators: Operators must be know at parse time, and Julia predefines
a collection of operators in a Scheme source file (see link below) belonging to the parse. These
can be freely defined/overloaded within Julia, but note also their associativity
(right or left) and their [precendence]. There are several binary and only few
unary operators (and very few n-ary: + and *).
? every operator listed as prec-arrow or prec-power in file below is right-associative.
The only unary operators in Julia are <: >: + - ! ~ ¬ √ ∛ ∜, all of which are parsed as acting from the left. Plus ' and .', of course, which are postfix operators.
https://github.com/JuliaLang/julia/blob/master/src/julia-parser.scm

=#

#=
Using string macros (Non-Standard String Literals)
Example creating a version number type: v"1.2.3"
VersionNumber("1.2.3")

macro v_str(v); VersionNumber(v); end

For notes: quarter note C-sharp with given dynamics
n"1/4 c♯4 pp"
This is rather concise, just three chars added
Of course, I could also have this as a function:
n(1/4 :c♯4 :pp)
=#

#=
Musical parameters having vtheir own type (e.g., a pitch type and a note value type)
allows for specialising methods (like +) for these types.
Creating note instances directly from, say, integers and symbols is still possible.
=#


# export MyType, foo

# TODO:
struct Note
    pitch
end


struct Pitch{T<:Real} <: Real
    # _ is name of a field we do not really care about
    _::T

    # TODO: inner constructor needed?
    Pitch{T}(x) where {T<:Real} = new(x)
end
Pitch(x::T) where {T<:Real} = Pitch{T}(x);
# TODO: constructor creating pitch from symbol

#=
!! You can have an OMN-like concise syntax for music expressions, but with
full typing support for notes and individual parameters by defining various
constants for my OMN-equivalent "symbols"
=#

#= TODO:
- Proper microtonal support: define struct etc. for [Pyhthagorean] [base notes]:
  C, D, E, ... B, perhaps even with an internal representation of their pitch ratios (??)
  ... pitch depends on the tuning system. I could initially use pitch ratios, and
  later allow for equal temeraments etc.
  and later generalise for other tuning systems
- Define accidentals as a transposition, initially as a factor of pitch ratios,
  later this can be overwritten (e.g., by an addition of equal temperament pitches)
  - For supporting dynamic tuning system changes I would need some unified system
    with one or more parameters
- Define pitch constructor expecting symbols
- Define Base.show for pitches displaying the corresponding symbols
  (created automatically from PC and octave?)
  NOTE: How to preserve accidental? With full type machinery there will be a way
  (e.g., simply using 31-TET PCs for now internally – that could be revised later)
- Define pitch class type, internally storing reals
- Define consts for standard pitch classes (retaining accidental??)
- Define macro (?) or other automatic means for turning all pitch classes and
  all octaves into constants of pitch symbols
=#
# Better: this notation should be pitch class multiplied by int representing octave
const C♯4 = Pitch(60)

# Now I can compute with such pitch "symbols" using the full typing machinery
C♯4

#=
Create type for pitch intervals as well.
Then I can do simple math with pitches, e.g.,
- Adding pitches directly
- Adding ints to pitches for convenience
- ? Adding pitch classes to pitches -- should that return a pitch or a pitch class?
- Adding intervals to pitches
Likewise with pitch classes and intervals

Generalise this for math on sets and arrays of pitches, pitch classes and intervals, e.g.,
by specialising broadcasting to my types (if that is even necessary – I may simply
use vectors for expressing sequences for a while)
https://julialang.org/blog/2018/05/extensible-broadcast-fusion
https://docs.julialang.org/en/latest/manual/interfaces/#man-interfaces-broadcasting-1


The overall result is something like Pachet's MusES, but with a mix of Janusz'
OMN-like music syntax and plain math syntax, e.g.,

C♯ + 5 == G♯
C♯ + fifth == G♯

With an interface to Gecode, Minizinc or perhaps a Julia library such as JuMP
(?? so far they recomment to instead use Minizinc, https://discourse.julialang.org/t/jump-allunique-as-a-constraint/9569)
I could turn this into a music constraint
system with very clear syntax, but I am not sure whether I need that...
=#

#=
The same I can do for rhythmic values, using later either fractions directly
or OMN symbols for rhythmic values.
NOTE: OMN symbols for rhythmic values are composable. I can have something
equivalent by defining operators for rhythmic values, e.g.,
h+h == w
q*4 == w
h/3 (or something similar) is triplet
? h' (unary '-operator)  for dotted notes
...

=#

#=
Creating note objects from flat sequence of typed (!) values, e.g.,
voice = [1//4 C4 1//4 G4]
voice = [q C4 h G4]

Simple implementation (first hack):
 - Require every note to have an explicit rhythmic value.
   I.e., in contrast to OMN, the following is not possible
   voice = [q C4 G4]
- Split given vector at every rhythmic value
- Turn those subvectors into individual notes
Possible later refinement (incomplete algorithm sketch)
- Detect multiple pitches (or other parameters) in subvectors
- Create a note with the parameters before the type repetition
- Create further notes with following types...

=#


p1 = Pitch(60)
p2 = Pitch(60 + 1//2)

p1._

# Base.convert(::Type{Real}, x::Pitch) = x._


convert(::Type{Pitch}, x::Real) = Pitch(x)
# convert(Pitch, 61)

# TODO: better call promote inside of def?
convert(::Type{T}, x::Pitch) where {T<:Real} = convert(T, x._)

convert(Real, p1)
convert(Float64, p1)
convert(Float64, p2)

# promote_rule(::Type{BigInt}, ::Type{Float64}) = BigFloat

# TODO: should result of adding, say, a pitch and an int not better be another pitch?
# Does it actually mae sense to add numbers to pitches?
# Already there even without having a promote rule defined
promote_type(Integer, Pitch)

# error
float(p1)

# Error
Pitch(60) + Pitch(1)

Type{p2}


# TMP (I probably don't need 64 bits for pitches?)
# TODO: Perhaps better have a struct with a single value?
# TODO: ?? consider turning into a parameteric type that supports both ints and symbols
# TODO: define constructor
# ? primitive type Pitch <: Unsigned  64 end

# TODO: how to have a short easily readable representation of pitches
# Ideally only a single leading character (even unicode, but that might be
# clumsy to add) to mark type, e.g., p60 to specify the pitch
# Can be done with quasi read marcros, but they work on strings

# Alternative: use plain primite types (e.g., integers) and automatically
# convert types to, e.g., pitches depending on context. But, why should I have
# then an extra type for pitches in the first place?

# Example: See definition of parsing etc of special syntax of Rationals below
# Do something similar and concise for notes?

Pitch(60)

typeof(p1)
typeof(Pitch)

Pitch <: Real


Rational

Int64

show(io::IO, a::Note) = print(io, "Note $(a.x)")

#=
# Reading and writing of Rationals -- I should do something similar for notes
# Together with definition of operator //
See https://github.com/JuliaLang/julia/blob/master/base/rational.jl

//(n::Integer,  d::Integer) = Rational(n,d)

function show(io::IO, x::Rational)
    show(io, numerator(x))
    print(io, "//")
    show(io, denominator(x))
end

function read(s::IO, ::Type{Rational{T}}) where T<:Integer
    r = read(s,T)
    i = read(s,T)
    r//i
end
function write(s::IO, z::Rational)
    write(s,numerator(z),denominator(z))
end
=#



########################
# Music-related unicode symbols
# https://en.wikipedia.org/wiki/Musical_Symbols_(Unicode_block)
# https://www.unicode.org/charts/PDF/U1D100.pdf

# Dynamics symbols are included, but these are way too small.

# I tried already a number of different monospace fonts, but I cannot see
# any change to the actual symbols. It is well possible that the symbols are
# defined by another font. Possibly I should combine fonts (monospace and music
# font), but I did not yet find a suitable combination.

# Consider changing the font (or perhaps even editing it)
# This problem could be the width of the symbols in a monospace font?
# TODO: check out which unicode fonts support music symbols well, and are also
# monospace (likely very few...)
# Same question with answers, but I did not find anything with this info yet
# https://graphicdesign.stackexchange.com/questions/81787/good-font-to-use-with-unicode-musical-symbols
# Search: https://elbsound.studio/music-fonts.php#unicode
# 7 unicode font that include music symbols, but they are serif fonts
# https://www.fontspace.com/unicode/char/1D15F-musical-symbol-quarter-note

# ??? Alt solution: Perhaps in the Atom editor I can change the font size of
# these symbols with CSS -- most likely not, I think I confused options here

# Default fonts in preferences: Menlo, Consolas, DejaVu Sans Mono, monospace

#=
♮C

♩

𝆏 𝆐 𝆑 𝆑

𝆏 = 30
𝆏

♩ =
𝅘𝅥𝅮 =


𝅝
𝅗
𝅘
𝆕 𝆕

𝄞 𝄚 𝄚

test 𝆏 𝆐 𝆑 𝆑 𝆕 𝆕 𝄰 𝆏 = 30

¬ true

# short name for note? \scn
𝓃

=#


#
