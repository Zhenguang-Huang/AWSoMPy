# Generate event_list with background and restart !!
# Format for new event list combining background and restart

# ----------------------------------------------------------------------------------------------------------------------

# EEGGL parameters:
# 87.50                   LongitudeCme
# 14.50                   LatitudeCme
# 250.68                  OrientationCme
# -18.81                  BStrength
# 0.75                    Radius
# 0.60                    Stretch
# 0.95                    ApexHeight

# #START
# 1 restart=run***  OrientationCme=*** ApexHeight=***
# 2 restart=run***  OrientationCme=*** ApexHeight=***
# 3 restart=run***  OrientationCme=*** ApexHeight=***

# ----------------------------------------------------------------------------------------------------------------------


using CSV
using DataFrames
using IterTools
using Printf
using Dates
using Distributions
using DelimitedFiles

# DONE:
# - Can take in multiple background runs and write run IDs correctly
# - No params that are in the background repeat for the CME runs
# - added param = PARAM.in.awsom.cme

# TO DO: 
# - add ArgParse with options to specify restartdir from the command line? 
# - options - define variable that lists selected background, then have restart = those runs in sequence, 
# but restart params repeat. 
# - how do we write in EEGGL params at top? Take from a separate file and merge ? 


# restartdir - directory containing background runs to restart (if linking to existing runs)
# N/A here?

# specify mg, cr and md
mg = "ADAPT"
cr = 2154
md = "AWSoM"

# number of background runs - load a csv and count
# nBackground = 1

# load file for background params
XBackground = DataFrame(CSV.File("./SampleOutputs/restartRunDesignFiles/3params_background_0928.csv"))
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
XRestart = DataFrame(CSV.File("./SampleOutputs/restartRunDesignFiles/X_design_CME_2021_10_01.csv"))
deletecols!(XRestart, "Column1")

# convert EEGGL Method from (1, 2) to (Distance, Area) => 1 = Distance, 2 = Area
EEGGLMethod = replace(XRestart.EEGGLMethod, 1=>"Distance", 2=>"Area")
select!(XRestart, Not(:EEGGLMethod))
insertcols!(XRestart, :EEGGLMethod=>EEGGLMethod)


colNamesRestart = [
                "Strength",
                "Radius",
                "dOrientationCme",
                "ApexHeight",
                "FootptDistance",
                "Helicity",
                "EEGGLMethod"
                ]   # give column names for data frame

rename!(XRestart, colNamesRestart)

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

    write(tmpio, 
        string(count) * " " * stringToWrite * "\n")

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


