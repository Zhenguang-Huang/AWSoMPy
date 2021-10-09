module SelectInputs


using LinearAlgebra
# using Plots
using Distributions
using Random


# Define new type for variables with a default setting that may be assigned some probability mass according to user's choice.
struct MixedRandomVariable
	minVal::Float64			# minimum value taken by the variable
	defVal::Float64 			# default value taken by the variable
	maxVal::Float64 			# maximum value taken by the variable
	probDef::Float64 		# Probability of selecting default values

	# Define inner constructor for initializing - default probability is 0.0
	MixedRandomVariable(minVal, defVal, maxVal) = new(minVal, defVal, maxVal, 0.0)

	# Define inner constructor with non-default probability values
	function MixedRandomVariable(minVal, defVal, maxVal, probDef)
		if probDef >= 0 && probDef <= 1
			return new(minVal, defVal, maxVal, probDef)
		else
			return error("Probability not in valid range")
		end
	end

end


import Random: rand
	
function rand(rng::AbstractRNG, mrv::Random.SamplerTrivial{MixedRandomVariable})
    if rand() < mrv[].probDef
        # if true return default value (by default, probDef = 0 => never selected!)
        return mrv[].defVal
    else
        # else sample from Uniform(min, max) - this is the case for most i/p s.
        return rand(rng, Uniform(mrv[].minVal, mrv[].maxVal))
    end
end




export MixedRandomVariable, rand

end

