# Instead of writing the same runs across all 16 groups, we randomize the runs across all groups
# Runs are now implemented with TAB spacing (where TAB didn't work as expected, 4 spaces.)
# Removing rCollisional. Augmenting LHS instead with UseSurfaceWaveRefl that takes true or false as input. 
# Using default values of SCHEME, UseNonConservative, GridResolution - hence not written to the event list file. 

# Import modules into workspace
# These "modules" contain some necessary functions needed to sample from some RVs as well as creation of LHS designs 
include("SelectInputs.jl")
include("LHSDesign.jl")

# Import necessary packages
using CSV
using DataFrames
using IterTools
using Printf
using Dates
using Distributions

# Let's also fix the seed for generating the list and save that as an additional comment (for reproducibility purposes) 
using Random
runGeneratingSeed = 8191
Random.seed!(runGeneratingSeed)



# fetch current date and time and add to generated file
currDateTime = Dates.now()
currDTString = Dates.format(currDateTime, "yyyy_mm_dd_HH_MM_SS")

# specify full file name
fileName = currDTString * "_event_list_randomized.txt"
# fileName = "event_list.txt"

# make dataframe from all combinations of params and write rows of dataframe to lines of text file

# we can add more entries in mg and cr if required, code handles all combinations
mg = ["GONG", "ADAPT"]
cr = [2208, 2209, 2152, 2154]
md = ["AWSoM", "AWSoMR"]

REALIZATIONS_ADAPTvals = collect(1:12)
PFSSVals = ["HARMONICS";
            "FDIPS"]
# BrMin_Vals = SelectInputs.MixedRandomVariable(5.0, 0.0, 10.0)
BrMin_Vals = [0.0, 10.0]

# Add in vals for UseSurfaceWaveRefl
UseSurfaceWaveRefl_Vals = ["T";
                           "F"]

# Assumptions: Separate groups based on `model`, `magnetogram`, and `CRVals`. Fixed values for `nOrderVals`, `NonConservativeVals` and `GridResolutionVals`.

# We will use the following order for the real valued variables while creating columns of upper bounds and lower bounds. 
# Order: BrFactor_GONG, BrFactor_ADAPT, rMin_AWSoMR, nChromoSi_AWSoM, PoyntingFluxPerBSI, LperpTimesSqrtBSI, StochasticExponent. 
lowerBounds = [1.0, 0.54, 1.05, 2e17, 0.3e6, 0.3e5, 0.1]
upperBounds = [4.0, 2.7, 1.15, 5e18, 1.1e6, 3e5, 0.34]

# We will augment rMinWaveReflection separately, since we are imposing an additional constraint that it should be greater than rMin_AWSoMR. 


pRV = length(lowerBounds)
nRV = 6
nRVTotal = length(product(mg, cr, md)) * 6 # if we wanted fixed number of runs for all groups, we would remove length(product(...))


designMatrix  = []
using IterTools
for p in product(mg, cr, md) # product iterates over all combinations of its arguments
    for runNumber in 1:nRV
        push!(designMatrix, p)
    end
end

dfDesign = DataFrame(designMatrix)          # make dataframe out of array of tuples generated from above loop
colNames = ["magnetogram", "cr", "model"]   # give column names for data frame
rename!(dfDesign, colNames)

# Create column for model based on mg and cr
insertcols!(dfDesign, 2, :map => string.(dfDesign[:magnetogram], "_CR", dfDesign[:cr],  ".fits"))
deletecols!(dfDesign, [1, 3])

io = open(fileName, "w")
write(io, "selected run IDs = 1-$(size(dfDesign, 1))\n")
write(io, "#START\n")

for count = 1:size(dfDesign, 1)
    dfCount = dfDesign[count, :]
    dictCount = Dict(names(dfCount) .=> values(dfCount))
    stringToWrite = ""
    for (key, value) in dictCount
        appendVal = string(key, "=", value, "   ")
        stringToWrite = stringToWrite * appendVal
    end
    write(io, string(count) * " " * stringToWrite * "\n")
end
close(io)

# Call LHSDesign function with appropriate arguments
X, _, _ = LHSDesign.lhsdesign(nRVTotal, pRV, 100)
X_regular = (upperBounds - lowerBounds)'.* X .+ lowerBounds'

# Augment with columns from categorical variables and mixed RV. 
PFSS               = rand(PFSSVals, nRVTotal, 1)
REALIZATIONS_ADAPT = rand(REALIZATIONS_ADAPTvals, nRVTotal, 1)
# need to create separate variables for BrMin_GONG and BrMin_ADAPT (different default values, same range)
BrMin              = rand(BrMin_Vals, nRVTotal, 1)

# Add column for UseSurfaceWaveRefl
UseSurfaceWaveRefl = rand(UseSurfaceWaveRefl_Vals, nRVTotal, 1)

# Extract columns for dependent factors from X_regular (these depend on model or map used)
BrFactor_GONG   = X_regular[:, 1]
BrFactor_ADAPT  = X_regular[:, 2]
rMin_AWSoMR     = X_regular[:, 3]
nChromoSi_AWSoM = X_regular[:, 4]

# Make function to impose constraint on rMinWaveReflection
function getrMinWaveSample(rMin_AWSoMR_Sample)
    rMinWaveSample = rand(Uniform(1, 1.2))
    if rMinWaveSample > rMin_AWSoMR_Sample
        return rMinWaveSample
    else
        getrMinWaveSample(rMin_AWSoMR_Sample)
    end
end

# create rMinWaveReflection column. 
rMinWaveReflection = []
for eachSample in rMin_AWSoMR
    push!(rMinWaveReflection, getrMinWaveSample(eachSample))
end

designMatrixLHS = hcat(
                       REALIZATIONS_ADAPT,
                       X_regular, 
                       UseSurfaceWaveRefl,
                       rMinWaveReflection, 
                       PFSS,  
                       BrMin
                       )
dfLHS = DataFrame(designMatrixLHS)

colNamesLHS = [
"REALIZATIONS_ADAPT", 
"BrFactor_GONG", 
"BrFactor_ADAPT",
"rMin_AWSoMR",
"nChromoSi_AWSoM",
"PoyntingFluxPerBSi",
"LperpTimesSqrtBSi",
"StochasticExponent",
"UseSurfaceWaveRefl",
"rMinWaveReflection", 
"pfss",
"BrMin"
]
rename!(dfLHS, colNamesLHS);


# this file will be merged with base event list file and removed at the end of the program. 
fileNameLHS = currDTString * "_lhsDesignMatrix.txt"
ioLHS = open(fileNameLHS, "w")

for count = 1:size(dfLHS, 1)
    dfCount = dfLHS[count, 6:end]
    dictCount = Dict(names(dfCount) .=> values(dfCount))
    stringToWrite = ""
    for (key, value) in dictCount
        # insert conditions for appropriate string formatting
        if value isa String
            appendVal = @sprintf("%s=%s    ", key, value)
        elseif value >=1000
            appendVal = @sprintf("%s=%e    ", key, value)
        else
            appendVal = @sprintf("%s=%.4f    ", key, value)
        end
        # appendVal = string(key, "=", value, " ")
        stringToWrite = stringToWrite * appendVal
    end
    write(ioLHS, "    " * stringToWrite * "\n")
end
close(ioLHS)

io = open(fileName);
linesBase = readlines(io)
close(io)

ioLHS = open(fileNameLHS)
linesLHS = readlines(ioLHS)
close(ioLHS)

# Merging operation done in loops below
(tmppath2, tmpio2) = mktemp()
write(tmpio2, "selected run IDs = 1-$(size(dfDesign, 1))\n")
write(tmpio2, "#START\n")

for groupIdx = 1:length(product(mg, cr, md))
    runIdx = 0
    for lineIdx = (groupIdx - 1)*nRV + 1 + 2:groupIdx*nRV + 2
        runIdx += 1
        newLine = linesBase[lineIdx][1:end] * linesLHS[lineIdx - 2][2:end] * "\n"  # index linesLHS with lineIdx instead of runIdx
        write(tmpio2, newLine)
    end
end
close(tmpio2); 
mv(tmppath2, fileName, force=true)

# Separately created LHS runs file removed after merging
rm(fileNameLHS)

# write arbitrary realization number for ADAPT runs
# realization_idx = 1 # some number between 1 and 12 for baseline runs (fixed here, to be varied in later event lists)

# Change realization_idx between 1 and 12 randomly (call REALIZATIONS_ADAPT)
(tmppath, tmpio) = mktemp()
open(fileName) do f
runCounter = 0
    for line in eachline(f, keep=true)
        if occursin("map=ADAPT", line)
            runCounter += 1
            line = line[1:end-1]
            line = line * "realization=[$(REALIZATIONS_ADAPT[runCounter])]    \n"
        end
    write(tmpio, line)
    end
end
close(tmpio); 
mv(tmppath, fileName, force=true)

# insert realizations at ADAPT maps, BrFactor for GONG and ADAPT, rMin for AWSoMR and nChromoSi for AWSoM
io_event_list = open(fileName)
linesEventList = readlines(io_event_list)
close(io_event_list)

# Based on combinations of GONG, ADAPT, AWSoM, AWSoMR, fill in BrFactor, rMin_AWSoMR and nChromoSi_AWSoM
(tmppath3, tmpio3) = mktemp()

# Add in the following lines that include the random seed in comments
write(tmpio3, "# runGeneratingSeed = $(runGeneratingSeed)\n")
write(tmpio3, "# Runs generated using Random.seed!() in Julia\n")
write(tmpio3, "#                                         \n")

write(tmpio3, "selected run IDs = 1-$(size(dfDesign, 1))\n")
write(tmpio3, "#START\n")
write(tmpio3, "ID   params\n")
for groupIdx = 1:length(product(mg, cr, md))
    runCounter = 0
    for lineIdx = (groupIdx - 1)*nRV + 1 + 2:groupIdx*nRV + 2
        runCounter += 1
        # insert conditions for appropriate string formatting
        if occursin("map=GONG", linesEventList[lineIdx]) && occursin("model=AWSoMR", linesEventList[lineIdx])
            newLine = linesEventList[lineIdx] * @sprintf("BrFactor=%.4f    ", BrFactor_GONG[lineIdx - 2]) * @sprintf("rMin_AWSoMR=%.4f    ", rMin_AWSoMR[lineIdx - 2]) * "\n"
        elseif occursin("map=GONG", linesEventList[lineIdx]) && occursin("model=AWSoM", linesEventList[lineIdx])
            newLine = linesEventList[lineIdx] * @sprintf("BrFactor=%.4f   ", BrFactor_GONG[lineIdx - 2]) * @sprintf("nChromoSi_AWSoM=%e    ", nChromoSi_AWSoM[lineIdx - 2]) * "\n"
        elseif occursin("map=ADAPT", linesEventList[lineIdx]) && occursin("model=AWSoMR", linesEventList[lineIdx])
            newLine = linesEventList[lineIdx] * @sprintf("BrFactor=%.4f   ", BrFactor_ADAPT[lineIdx - 2]) * @sprintf("rMin_AWSoMR=%.4f    ", rMin_AWSoMR[lineIdx - 2]) * "\n"
        elseif occursin("map=ADAPT", linesEventList[lineIdx]) && occursin("model=AWSoM", linesEventList[lineIdx])
            newLine = linesEventList[lineIdx] * @sprintf("BrFactor=%.4f   ", BrFactor_ADAPT[lineIdx - 2]) * @sprintf("nChromoSi_AWSoM=%e    ", nChromoSi_AWSoM[lineIdx - 2]) * "\n"
        else
            newLine = linesEventList[lineIdx] * "\n"
        end

        write(tmpio3, newLine)
    end
end
close(tmpio3); 
mv(tmppath3, fileName, force=true)
