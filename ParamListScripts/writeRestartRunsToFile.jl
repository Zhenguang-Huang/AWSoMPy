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

# TO DO: 
# - options - define variable that lists selected background, then have restart = those runs in sequence, 
# but restart params repeat. 
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
    description="Generate event list for background and restart")
@add_arg_table s begin
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
    "--fileEEGGL"
        help = "Path to load EEGGL Params from."
        arg_type = String
        default = "./output/restartRunDesignFiles/EEGGLParams_CR2154.txt"
    "--fileBackground"
        help = "Path to load background wind runs from."
        arg_type = String
        default = "./output/restartRunDesignFiles/3params_background_0928.csv"
    "--fileRestart"
        help = "Path to load restart runs from."
        arg_type = String
        default = "./output/restartRunDesignFiles/X_design_CME_2021_10_08.csv"
    "--start_time"
        help = "start time to use for background. Can give yyyy-mm-ddThh:mm:sec:fracsec"
        default="MapTime"
    "--restartID"
        help = "give selected background run to which to apply restarts. For example, run005_AWSoM"
        arg_type = String
        default="run001_AWSoM"  # This is a bad idea, also what if we give multiple runs
    # "--runListFile"
    #     help = "Give path to file where we wish to write runlist"
    #     default = "run_list_" * mg * "_" * md * "_" * 
    #             "CR$(cr)" * "_" * Dates.format(Dates.now(), "yyyy_mm_dd") * ".txt"
    # this is broken because I set the default name to need a CR, 
    # which is an unparsed arg :(
end

args = parse_args(s)

# restartdir - directory containing background runs to restart (if linking to existing runs)
# N/A here?

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

# Get filename for output
paramListFileName = "param_list_" * mg * "_" * md * "_" * 
            "CR$(cr)" * "_" * Dates.format(Dates.now(), "yyyy_mm_dd") * ".txt"

# Write EEGGL params in header
write(tmpio, "#CME\n")
for (key, value) in eegglParams
    write(tmpio, "# " * value * "           " * key * "\n")
end    

write(tmpio, "selected run IDs = 1-$(size(XRestart, 1) + nBackground)\n")
write(tmpio, "#START\n")
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

# Get restart run ID (enabled just for a single best run for now)
restartID = args["restartID"]

# Loop through DataFrame for restart
for count = 1:size(XRestart, 1)
    dfParams = XRestart[count, 1:end]
    dictParams = Dict(names(dfParams) .=> values(dfParams))
    stringToWrite = ""

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

    write(tmpio, 
        string(runIDRange[count]) * " " * "restartdir=$(restartID)         " * " param=PARAM.in.awsom.cme      " * stringToWrite * "\n")
end
# end for loop

# close or flush the temporary IO stream
flush(tmpio)

# Move the temporary file (src) to appropriate location (dst), force=true overwrites dst if it already exists 
mv(tmppath, joinpath("./output/", paramListFileName), force=true)

# confirmation message
println("Wrote restart runs")
println("Successfully wrote runs to file " * paramListFileName)