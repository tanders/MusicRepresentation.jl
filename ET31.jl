
# module ET31


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
     "𝄫"=>24//25 * 24//25)



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
accidentals = ratio_to_keynum(ji_accidentals, pitches_per_octave)

# BUG: contains errors. The problem is that Pythagorean JI nominals are not suitable for meantone. 81//64 is not 5//4
nominals = ratio_to_keynum(ji_nominals, pitches_per_octave)

#=
ratio_to_cent(ji_nominals["E"])
ratio_to_cent(5//4)

ratio_to_keynum(81//64, 31)
ratio_to_keynum(5//4, 31)

# No rounding error. Hm...
ratio_to_keynum_real(81//64, 31)
ratio_to_keynum_real(5//4, 31)
=#



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
