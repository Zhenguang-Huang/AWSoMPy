# Generate param_list with background and restart - read background runs csv, restart runs csv as well as an EEGGL Params list
#  and merge them by converting them as follows:
# CSV --> DataFrame --> Dictionary with Keys equal to column names and values equal to param value for that run ---> append `key = value`
# to a string and write string to a file ---> write final list with appropriate date at the end.

# Earlier versions had full date and time but this is 
# unnecessary, we will just overwrite a previously written file on the same date if it needs changes. 

# Format for new param list combining background and restart

# ----------------------------------------------------------------------------------------------------------------------
# EEGGL parameters in header
#CME
# T                   UseCme
# T                   DoAddFluxRope
# 87.50               LongitudeCme
# 14.50               LatitudeCme
# 251.57              OrientationCme
# GL                  TypeCme
# -30.10              BStrength
# 0.42                Radius
# 0.60                aStretch
# 0.62                ApexHeight

# #START
# 1 model=          map=                BrFactor=       PoyntingFluxPerBSi=         LperpTimesSqrtBSi=
# (same upto nb runs, optionally has time=      if start_time has been specified)

# nb+1  restart=run***  OrientationCme=*** ApexHeight=***
# nb+2  restart=run***  OrientationCme=*** ApexHeight=***
# (same up to nb + nr runs)
# nb+nr restart=run***  OrientationCme=*** ApexHeight=***

# ----------------------------------------------------------------------------------------------------------------------
# DONE:
# - Can take in multiple background runs and write run IDs correctly
# - No params that are in the background repeat for the CME runs
# - added param = PARAM.in.awsom.cme
# - add ArgParse with appropriate options so you can easily modify arguments from command line to generate new list
# - dropped FootptDistance and EEGGLMethod
# - drop helicity - not used directly
# - variable renaming + lots of formula corrections + dropping some variables entirely
# - EEGGL params now read from file and put into header
# - removing start_time arg for now since we are checking for Date_CME from EEGGL file
# - put in ability to give a single background run, which will be written as restartdir = selectedRun
# - rename filepaths to be consistent with renamed directories
# - put in ability to give all or an arbitrary set of background runs.

# TO DO: 
# - write a separate utilities / tools script that exports a module with helpful functions (for eg: parsing function later in this script)
# - write helper function for parsing dates supplied in arbitrary formats - low priority
# - also write out seed used while producing list in R? Helps keep track for reproducing if needed. 
# - other options? for eg: path to output. Currently trying to have a default path also contain CR, which is a different arg. 
# - use RCall and call the R MaxPro package directly from Julia? Might help integrate all steps from generating design to writing it
# - but more difficult to run the script since other users must also have R installed. 

using CSV
using DataFrames
using IterTools
using Printf
using Dates
using Distributions
using DelimitedFiles

using ArgParse

s = ArgParseSettings(
    description="Generate run list for background and restart")
@add_arg_table s begin
    "--fileEEGGL"
        help = "Path to load EEGGL Params from."
        arg_type = String
        default = "./output/restartRunDesignFiles/EEGGLParams_CR2154.txt"
    "--fileBackground"
        help = "Path to load background wind runs from."
        arg_type = String
        default = "./output/restartRunDesignFiles/Params_MaxPro_postdist.csv"
    "--fileRestart"
        help = "Path to load restart runs from."
        arg_type = String
        default = "./output/restartRunDesignFiles/X_design_CME_2021_10_18.csv"
    "--fileOutput"
        help = "Give path to file where we wish to write param list"
        default = "./output/param_list_" * Dates.format(Dates.now(), "yyyy_mm_dd") * ".txt"
    "--mg"
        help = "Magnetogram to use, for example, GONG."
        default = "ADAPT"
    "--cr"
        help = "CR to use eg: 2152."
        arg_type = Int
        default = 2154
    "--md"
        help = "Model to use, for example AWSoM, AWSoMR, AWSoM2T."
        default = "AWSoM"
    "--start_time"
        help = "start time to use for background. Can give yyyy-mm-ddThh:mm:sec:fracsec"
        default="MapTime"
    "--restartID"
        arg_type = Any
        help = "give one or more selected background runs to which to apply restarts. defaults to 'all', 
        i.e. all backgrounds are used.
        If for eg, '5' is supplied, then restartdir will be printed as `run005_MODEL` where MODEL can be, say, AWSoM
        If for eg, '1 3 5 7' is supplied, and nRestart > nBackground, then we will cycle through 1, 3, 5, and 7 till restart runs are written. 
        It is flexible in that we can give '1, 3, 5, 7', '1,3,5,7' or '1 3 5 7' and all are valid.
        Another option is to specify a range directly, for eg '1:2:8' will return the same output. Another valid range example is '1:100'.
        Note that all these arguments have to supplied in double quotes, and parsing functions in the script take care of the rest."
        default="all"
end

args = parse_args(s)

# specify mg, cr and md
mg = args["mg"]
cr = args["cr"]
md = args["md"]

# load file for background params
fileBackground = args["fileBackground"]
XBackground = DataFrame(CSV.File(fileBackground))
# count number of background runs
nBackground = size(XBackground, 1) # Going to set it to 20 assuming we just do the runs from the CSV file 
# Add columns for writing out .fits fileName and model
insertcols!(XBackground, 1, :map=>string(mg, "_CR", "$(cr)",  ".fits"))
insertcols!(XBackground, 2, :model=>md)

colNamesBackground = [
                    "map",
                    "model",
                    "BrFactor", 
                    "PoyntingFluxPerBSi", 
                    "LperpTimesSqrtBSi"
                    ]

rename!(XBackground, colNamesBackground)


# load file for restart params
fileRestart = args["fileRestart"]
XRestart = DataFrame(CSV.File(fileRestart))
deletecols!(XRestart, "Column1")

colNamesRestart = [
                "RelativeStrength",
                "CmeRadius",
                "DeltaOrientation",
                "ApexCoeff",
                "Helicity",
                ]   # give column names for data frame (can be redundant if names are already correct)

rename!(XRestart, colNamesRestart)

# Now read in the file with EEGGL params
fileEEGGL = args["fileEEGGL"]

# Write a function that takes in fileEEGGL, extracts EEGGLParams 
function getEEGGLParams(f::IOStream)
    println("Opened EEGGL file")
    eegglParams = Dict()
    iParamStart = 2 
    # Hardcoding for now, problems with break, ideally want the loop below:
    # for (iLine, line) in enumerate(readlines(f))
    #     if occursin("#CME", line[1:4])
    #         iParamStart = iLine + 1
    #         break
    #     end
    # end
    println("Found #CME")
    lines = readlines(f)
    # Extract param names and values and store them in `eegglParams`
    for line in lines[iParamStart:end]
        strValue, nameEEGGL = split(line)
        eegglParams[nameEEGGL] = strValue
    end 
    println("Got EEGGL Parameters")
    return eegglParams
end

# Call the above function with filename for eeggl params
eegglParams = open(getEEGGLParams, fileEEGGL)

# Parse values for the event specific parameters 
Radius_EEGGL        = parse(Float64, eegglParams["Radius"])
B_EEGGL             = parse(Float64, eegglParams["BStrength"])
Orientation_EEGGL   = parse(Float64, eegglParams["OrientationCme"])

# Date_CME is not in the EEGGL file, so we will just use start_time as an arg to be
# supplied when running the file.

# Corrected formulae:
# 1) Radius    = CmeRadius - produce this first
# 2) BStrength = RelativeStrength * |B_EEGGL| * Helicity * (Radius_EEGGL / Radius)
# 3) ApexHeight = Radius * ApexCoeff
# 4) Orientation = Orientation_EEGGL + DeltaOrientation

# Deliberately splitting up insertion for radius and others, since others are dependent on radius. 
# Can be done in one go using CmeRadius instead of Radius in formulae, 
# but this would be catastrophic if we decided to change how we calculate Radius in the future!!!
insertcols!(
            XRestart,
            1, 
            :Radius         => XRestart.CmeRadius
        )

insertcols!(
            XRestart, 
            2,
            :BStrength      => (abs(B_EEGGL) * Radius_EEGGL * XRestart.Helicity)  .* (XRestart.RelativeStrength ./ XRestart.Radius),
            :ApexHeight     => XRestart.Radius .* XRestart.ApexCoeff,
            :Orientation    => XRestart.DeltaOrientation .+ Orientation_EEGGL
            )

# Discard distribution columns now, we don't want to write them to file!
deletecols!(
            XRestart, 
            colNamesRestart
            )

startTime = args["start_time"]

# count number of restarts
nRestart = size(XRestart, 1)

# start restart numbering from nBackground + 1
runIDRange = (nBackground + 1):(nBackground + nRestart)

# Create temporary file path and IO
(tmppath, tmpio) = mktemp()

# Get filename for output - we will use default filename for now
paramListFileName = args["fileOutput"]
# paramListFileName = "param_list_" * mg * "_" * md * "_" * 
#             "CR$(cr)" * "_" * Dates.format(Dates.now(), "yyyy_mm_dd") * ".txt"

# Write EEGGL params in header
write(tmpio, "#CME\n")
for (key, value) in eegglParams
    write(tmpio, "# " * value * "           " * key * "\n")
end    

write(tmpio, "\nselected run IDs = 1-$(size(XRestart, 1) + nBackground)\n")
write(tmpio, "\n#START\n")
write(tmpio, "ID   params\n")

# Extract keys and values from DataFrame and write as strings to param_list_file

# Loop through DataFrame for background
for count = 1:size(XBackground, 1)

    dfParams = XBackground[count, 3:end]
    dictParams = Dict(names(dfParams) .=> values(dfParams))

    dfMapModel = XBackground[count, 1:2]                      # By convention, map and model will be the first 2 columns
    dictMapModel = Dict(names(dfMapModel) .=> values(dfMapModel))
    stringToWrite = ""

    # we write map and model in a different loop to ensure they come first in each line of the list. 
    for (key, value) in dictMapModel
        appendVal = @sprintf("%s=%s    ", key, value)
        stringToWrite = stringToWrite * appendVal
    end

    for (key, value) in dictParams
        if value isa String
            appendVal = @sprintf("%s=%s    ", key, value)
        elseif value isa Array
            appendVal = @sprintf("%s=[%d]    ", key, value[1])
        elseif value >= 1000
            appendVal = @sprintf("%s=%e    ", key, value)
        else
            appendVal = @sprintf("%s=%.4f    ", key, value)
        end
        stringToWrite = stringToWrite * appendVal
    end

    # Here we will put conditional to write startTime or have it not appear in the param list (revert to MapTime)
    if startTime == "MapTime"
        write(tmpio, 
        string(count) * " " * stringToWrite * "\n")
    else
        write(tmpio, 
        string(count) * " time=$(startTime)   " * stringToWrite * "\n")
    end

end
println("Wrote background runs")

# Get restart run ID (enabled for a single or multiple runs)
function parseRestartDirs(suppliedRestartIDs::AbstractString)
    if occursin(":", suppliedRestartIDs)
        splitIDs = split(suppliedRestartIDs, r"(:\s+|:|\s+:\s+)")
        if length(splitIDs)==3
            return collect(range(parse(Int, splitIDs[1]), parse(Int, splitIDs[3]), step=parse(Int, splitIDs[2])))
        else
            return collect(range(parse(Int, splitIDs[1]), parse(Int, splitIDs[2]), step=1))
        end
    elseif suppliedRestartIDs == "all" 
        return collect(1:nBackground)
    else # covers the case of comma separated values
        splitIDs = split(suppliedRestartIDs, r"(,\s+|\s+|,)")
        return parse.(Int, splitIDs)
    end
end

restartIDs = parseRestartDirs(args["restartID"])
nBackgroundSelected = length(restartIDs)

# Determine number of times we will write selected background as restartdir (nCycles)
if mod(nRestart, nBackgroundSelected) == 0
    nCycles = floor(Int, nRestart / nBackgroundSelected)
else
    # we will do one extra cycle (shortened) if not perfectly divisible. i.e. if nRestart = 18 and nBackgroundSelected = 5,
    # then we will do 4 cycles, but 4th cycle will only have 1,2,3 written as restartdirs
    nCycles = floor(Int, nRestart / nBackgroundSelected) + 1 
end

restartRunCount = 0     # Keeps track of restart runs independent of background run loop.
# Now outer loop is through each cycle and keeps track of the restartdirs written
for cycle in 1:nCycles
    restartIDIdx = 1 # this will be used as restartIDs[restartIDIdx] which may or may not be 1.
    # inner loop goes through all the selected background runs. If on the last cycle, this may be terminated early with the help of `min`.
    for n in (cycle - 1) * nBackgroundSelected + 1:min(cycle * nBackgroundSelected, nRestart)
        global restartRunCount += 1
        dfParams = XRestart[restartRunCount, 1:end]
        dictParams = Dict(names(dfParams) .=> values(dfParams))
        stringToWrite = ""
        # innermost loop adds key, value pairs to the string that goes on each line
        for (key, value) in dictParams
            if value isa String
                appendVal = @sprintf("%s=%s         ", key, value)
            elseif value isa Array
                appendVal = @sprintf("%s=[%d]    ", key, value[1])
            elseif value >= 1000
                appendVal = @sprintf("%s=%e    ", key, value)
            elseif value isa Int
                appendVal = @sprintf("%s=%d     ", key, value)
            else
                appendVal = @sprintf("%s=%.4f    ", key, value)
            end
            stringToWrite = stringToWrite * appendVal
        end

        # Write string to tmpio, taking care of counts and indexing.
        write(tmpio, 
        string(runIDRange[restartRunCount]) * " " * 
        "restartdir=run" * @sprintf("%03d", restartIDs[restartIDIdx]) * "_" * "$(md)        " *
        " param=PARAM.in.awsom.CME      " * 
        stringToWrite * "\n")
        restartIDIdx += 1
    end
end

# close or flush the temporary IO stream
flush(tmpio)

# Move the temporary file (src) to appropriate location (dst), force=true overwrites dst if it already exists 
mv(tmppath, paramListFileName, force=true)

# confirmation message
println("Wrote restart runs")
println("Successfully wrote runs to file " * paramListFileName)