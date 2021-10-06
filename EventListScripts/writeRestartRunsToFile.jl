# Generate event_list with background and restart - read background runs csv, restart runs csv as well as an EEGGL Params list
#  and merge them by converting them as follows:
# CSV --> DataFrame --> Dictionary with Keys equal to column names and values equal to param value for that run ---> append `key = value`
# to a string and write string to a file ---> write final event_list with appropriate date at the end.

# Earlier versions had full date and time but this is 
# unnecessary, we will just overwrite a previously written file on the same date if it needs changes. 

# Format for new event list combining background and restart

# ----------------------------------------------------------------------------------------------------------------------

# EEGGL parameters (from Nishtha)
#CME
# Reading CME Para
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
# 1 restart=run***  OrientationCme=*** ApexHeight=***
# 2 restart=run***  OrientationCme=*** ApexHeight=***
# 3 restart=run***  OrientationCme=*** ApexHeight=***

# ----------------------------------------------------------------------------------------------------------------------
# DONE:
# - Can take in multiple background runs and write run IDs correctly
# - No params that are in the background repeat for the CME runs
# - added param = PARAM.in.awsom.cme
# - can also read in EEGGL params, calculate and put in final values instead of distribution values in event list
# - add ArgParse with appropriate options so you can easily modify arguments from command line to generate new event list :) 
# - corrected formula for BStrength
# - corrected formula for Radius - it should be Radius_distribution * Radius_EEGGL
# - dropped FootptDistance and EEGGLMethod
# - drop helicity - not used directly

# TO DO: 
# - options - define variable that lists selected background, then have restart = those runs in sequence, 
# but restart params repeat. 
# other options? for eg: path to output

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
@add_arg_table! s begin
    "--mg"
        help = "Which magnetogram?  eg: GONG"
        default = "ADAPT"
    "--cr"
        help = "Which CR are we analyzing for ? eg: 2152"
        default = 2154
    "--md"
        help = "Which model are we using? eg: AWSoM, AWSoMR, AWSoM2T"
        default = "AWSoM"
    # Disabling reading EEGGL file for now
    # "--fileEEGGL",
    #     help = "Path to load EEGGL Params"
    #     default = "./EEGGLParams/eeggl_params_2154.txt"
    "--fileBackground"
        help = "Path to load background wind runs"
        default = "./SampleOutputs/restartRunDesignFiles/3params_background_0928.csv"
    "--fileRestart"
        help = "Path to load restart runs"
        default = "./SampleOutputs/restartRunDesignFiles/X_design_CME_2021_10_01.csv"
    "--start_time"
        help = "start time to use for background"
        default="MapTime"
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

# convert EEGGL Method from (1, 2) to (Distance, Area) => 1 = Distance, 2 = Area
EEGGLMethod = replace(XRestart.EEGGLMethod, 1=>"Distance", 2=>"Area")
select!(XRestart, Not(:EEGGLMethod))
insertcols!(XRestart, :EEGGLMethod=>EEGGLMethod)

colNamesRestart = [
                "Strength_distribution",
                "Radius_distribution",
                "Orientation_distribution",
                "ApexHeight_distribution",
                "FootptDistance",
                "Helicity",
                "EEGGLMethod"
                ]   # give column names for data frame

rename!(XRestart, colNamesRestart)

# TO DO: Read file with EEGGL params
# For now: using values Nishtha supplied - 
BStrength_EEGGL         = -30.10
Radius_EEGGL            = 0.42
ApexHeight_EEGGL        = 0.62
OrientationCme_EEGGL    = 251.57

# Now use the formulas to create new columns for BStrength, Radius, ApexHeight and OrientationCme!
# BStrength = (BStrength_from_EEGGL + Strength_from_distribution) *  Helicity_from_distribution
# Radius      = Radius_from_EEGGL + Radius_from_distribution
# ApexHeight = ApexHeight_EEGGL + ApexHeight_distribution
# OrientationCme = OrientationCme_EEGGL + Orientation_distribution

insertcols!(
            XRestart, 
            1,
            :BStrength      => (XRestart.Strength_distribution .+ BStrength_EEGGL) .* XRestart.Helicity,
            :Radius         => XRestart.Radius_distribution .* Radius_EEGGL,
            :ApexHeight     => XRestart.ApexHeight_distribution .+ ApexHeight_EEGGL,
            :OrientationCme => XRestart.Orientation_distribution .+ OrientationCme_EEGGL
            )

# Discard distribution columns now, we don't want to write them to file!
deletecols!(
            XRestart, 
            [
            "Strength_distribution", 
            "Radius_distribution", 
            "ApexHeight_distribution", 
            "Orientation_distribution",
            "FootptDistance",
            "EEGGLMethod",
            "Helicity"
            ]
            )

# what does the start time param mean exactly? for now just putting in map time
startTime = args["start_time"]



# count number of restarts
nRestart = size(XRestart, 1)

# start restart numbering from nBackground + 1
runIDRange = (nBackground + 1):(nBackground + nRestart)

# fileName (make separate directory for restart event lists??)
currDateTime = Dates.now()
# currDTString = Dates.format(currDateTime, "yyyy_mm_dd_HH_MM_SS")
currDTString = Dates.format(currDateTime, "yyyy_mm_dd")
fileName = "event_list_" * mg * "_" * md * "_" * "CR$(cr)" * "_" * currDTString * ".txt"


# Extract keys and values from DataFrame and write as strings to event_list_file
(tmppath, tmpio) = mktemp()

# for loop for writing out to file
write(tmpio, "selected run IDs = 1-$(size(XRestart, 1) + nBackground)\n")
write(tmpio, "#START\n")
write(tmpio, "ID   params\n")

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

    # Here we will put conditional to write startTime or have it not appear in the event list
    if startTime isa DateTime # is this really the best way to do it :( ? 
        write(tmpio, 
        string(count) * " time = $(startTime)   " * stringToWrite * "\n")
    else
        write(tmpio, 
        string(count) * " " * stringToWrite * "\n")
    end

end


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
        string(runIDRange[count]) * " " * "restartdir=          " * " param=PARAM.in.awsom.cme      " * stringToWrite * "\n")
end
close(tmpio); 
mv(tmppath, joinpath("./SampleOutputs/", fileName), force=true)
# end for loop
# confirmation message
println("Successfully wrote runs to file " * fileName)