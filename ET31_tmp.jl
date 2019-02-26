
# module ET31

# TODO: reduce indentation level from 8 to 4 (perhaps simply copy into a new file?)
# TODO: turn all global vars into constants

# NOTE: needed?
const pitches_per_octave = 31


# See https://en.wikipedia.org/wiki/31_equal_temperament#Interval_size
# Also other ratios would have been possible (are tempered out)
# NOTE: combinations of accidentals are not supported with this approach yet, but I may add them by explicitly declaring for each accidental with which other accidentals it might be combined
# TODO: Can I recursively define values at some keys depending on values on other keys? (flat accidental fractions are the inverse of their corresponding sharp fractions). No, not with stateful programming.
ji_accidentals = Dict(
    # "x"=>4
    "𝄪"=>25//24 * 25//24,
    #"♯|"=>3,
    "𝄰"=>15//14, # septimal diatonic semitone
    "♯"=>25//24, # chromatic semitone
    "𝄯"=>49//48, # septimal diesis
    "♮"=>1//1,
#   ""=>0,
#   ";"=>-1,
     "𝄮"=>48//49,
     "♭"=>24//25,
#    "♭;"=>-3,
     "𝄭"=>14//15,
     # "♭♭"=>-4,
     "𝄫"=>24//25 * 24//25
     )



def_pitch_intervals(ji_accidentals)

# Test
#=
♯
𝄭
=#



#=
for (acc_name, acc_val) in ji_accidentals
        eval(:(const $(esc(Symbol(acc_name))) = $PitchInterval(acc_val)))
end

for (acc_name, acc_val) in ji_accidentals
        @defconstant(acc_name, PitchInterval(acc_val))
end

expr = [:(const $(esc(Symbol(acc_name))) = $PitchInterval(acc_val))
        for (acc_name, acc_val) in ji_accidentals]

expr[2]



function def_pitch_intervals_fn(intervals::Dict{String, Rational})

end

Expr(:escape, :test)
=#


# deduce tempered intervals automatically from accidentals defined as JI freq. ratios
# TODO: define as a function
accidentals = Dict(name => ratio_to_keynum(ratio, pitches_per_octave) for (name, ratio) in ji_accidentals)


#= # Old manual def
accidentals = Dict(
        # "♭♭"=>-4,
        "𝄫"=>-4,
#        "♭;"=>-3,
        "𝄭"=>-3,
        "♭"=>-2,
#        ";"=>-1,
        "𝄮"=>-1,
        "♮"=>0,
#        ""=>0,
        "𝄯"=>1,
        "♯"=>2,
        #"♯|"=>3,
        "𝄰"=>3,
        # "x"=>4
        "𝄪"=>4)
=#


# TODO: deduce this automatically from existing JI intervals
nominals = Dict(
        "C"=>0,
        "D"=>5,
        "E"=>10,
        "F"=>13,
        "G"=>18,
        "A"=>23,
        "B"=>28)

nominals = Dict()


# TODO: wrap code in function
pitchclass_names = merge(nominals, Dict("$nom_name+$acc_name" => nom_val+acc_val
        for (nom_name, nom_val) in nominals, (acc_name, acc_val) in accidentals))

# TODO: wrap code in function
# Mapping of PC ints to their symbols. Their can be more than one symbol per PC int.
pitchclass_ints = Dict{Integer, Vector{String}}()
for (name, int) in pitchclass_names
        missing_val = "nothing"
        curr = get(pitchclass_ints, int, missing_val)
        if curr === missing_val
                push!(pitchclass_ints, int => [name])
        else
                push!(curr, name)
        end
end


# TODO: def function that selects from options in pitchclass_ints a suitable pitchclass name, e.g., the shortest string (plain nominal), or as preference the string not containing microtonal intervals (or the opposite of the latter)
function pitchclass_name(pc::Integer)
        # All names matching pc
        names = pitchclass_ints[pc]
        # Position of plain nominal in names
        pos = findfirst(name -> length(name) == 1, names)
        if pos == nothing
                names[1] # simplification: just return first pitch name for now
        else
                names[pos]
        end
end


#= # tests

accidentals["♭"]

pitchclass_names["C"]
pitchclass_names["C+♯"]
pitchclass_names["D"]

pitchclass_ints[5]

pitchclass_name(0)
pitchclass_name(1)
pitchclass_name(2)
pitchclass_name(4)
pitchclass_name(5)

=#


#= # Orig port
pitchclasses = Dict(##"C♭♭"=>27
##"C♭;"=>28
##"C♭"=>29
"C;"=>30
"C"=>0
"C|"=>1
"C♯"=>2
"C♯|"=>3
"Cx"=>4

"D♭♭"=>1
"D♭;"=>2
"D♭"=>3
"D;"=>4
"D"=>5
"D|"=>6
"D♯"=>7
"D♯|"=>8
"Dx"=>9

"E♭♭"=>6
"E♭;"=>7
"E♭"=>8
"E;"=>9
"E"=>10
"E|"=>11
"E♯"=>12
"E♯|"=>13
"Ex"=>14

"F♭♭"=>9
"F♭;"=>10
"F♭"=>11
"F;"=>12
"F"=>13
"F|"=>14
"F♯"=>15
"F♯|"=>16
"Fx"=>17

"G♭♭"=>14
"G♭;"=>15
"G♭"=>16
"G;"=>17
"G"=>18
"G|"=>19
"G♯"=>20
"G♯|"=>21
"Gx"=>22

"A♭♭"=>19
"A♭;"=>20
"A♭"=>21
"A;"=>22
"A"=>23
"A|"=>24
"A♯"=>25
"A♯|"=>26
"Ax"=>27

"B♭♭"=>24
"B♭;"=>25
"B♭"=>26
"B;"=>27
"B"=>28
"B|"=>29
"B♯"=>30
## "B♯|"=>0
## "Bx"=>1
)
=#

# end
