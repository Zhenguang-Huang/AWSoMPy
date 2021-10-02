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

# TO DO: 
# - add ArgParse with options to specify restartdir from the command line? 
# - remove hardcoding for single background run ! 
# - options - define variable that lists selected background, then have restart = those runs in sequence, 
# but restart params repeat. 
# - how do we write in EEGGL params at top? Take from a separate file and merge ? 


# restartdir - directory containing background runs to restart (if linking to existing runs)
# N/A here

# specify mg, cr and md
mg = "ADAPT"
cr = 2154
md = "AWSoM"

# number of background runs - load a csv and count
# right now going with only 1 run so just going to hardcode that (not sure what values to put for now)
nBackground = 1

# load file for restart params
XDesign = DataFrame(CSV.File("/Users/ajivani/Desktop/X_design_CME_proposed_3.csv"))
deletecols!(XDesign, "Column1")

# convert EEGGL Method from (1, 2) to (Distance, Area) => 1 = Distance, 2 = Area
EEGGLMethod = replace(XDesign.EEGGLMethod, 1=>"Distance", 2=>"Area")
select!(XDesign, Not(:EEGGLMethod))
insertcols!(XDesign, :EEGGLMethod=>EEGGLMethod)


# Add columns for writing out .fits fileName and model
insertcols!(XDesign, 1, :map=>string(mg, "_CR", "$(cr)",  ".fits"))
insertcols!(XDesign, 2, :model=>md)

colNames = ["map",
            "model",
            "Strength",
            "Radius",
            "Orientation",
            "ApexHeight",
            "FootptDistance",
            "Helicity",
            "EEGGLMethod"
            ]   # give column names for data frame

rename!(XDesign, colNames)

# count number of restarts
nRestart = size(XDesign, 1)

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
write(tmpio, "selected run IDs = 1-$(size(XDesign, 1) + nBackground)\n")
write(tmpio, "#START\n")
write(tmpio, "ID   params\n")

# Loop through DataFrame
for count = 1:size(XDesign, 1)
    dfParams = XDesign[count, 3:end]
    dictParams = Dict(names(dfParams) .=> values(dfParams))
    stringToWrite = ""
    
    dfMapModel = XDesign[count, 1:2]
    dictMapModel = Dict(names(dfMapModel) .=> values(dfMapModel))

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

    write(tmpio, string(runIDRange[count]) * " " * "restart=run001_AWSoM " * stringToWrite * "\n")
end
close(tmpio); 
mv(tmppath, joinpath("./SampleOutputs/", fileName), force=true)
# end for loop
# confirmation message
println("Successfully wrote runs to file " * fileName)


