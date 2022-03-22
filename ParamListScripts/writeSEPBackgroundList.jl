## LOAD PACKAGES
using CSV
using DataFrames
using Dates
using DelimitedFiles
using Printf
using ArgParse

## PARSE ARGUMENTS
s = ArgParseSettings(
    description="Generate run list for SEP event background")
@add_arg_table s begin
    "--fileBackground"
        help = "Path to load background params from."
        arg_type = String
        default="./output/sep_param_lists/SEP_Background_20220321.csv"
    "--fileOutput"
        help = "Give path to file where we wish to write param list"
        default = "./output/sep_param_lists/param_list_SEP_bg_" * Dates.format(Dates.now(), "yyyy_mm_dd") * ".txt"
    "--fileParam"
        help = "Give path to correct PARAM file (specify in restarts AND check for keywords"
        default = "../Param/PARAM.in.awsomr.SCIHOHSP"
    "--fileMap"
        help = "Give filename of map to be used, for eg: `ADAPT_41_GONG_CR2161.fts`."
        default = "gong_201304110604.fits"
    "--md"
        help = "Model to use, for example AWSoM, AWSoMR, AWSoM2T."
        default = "AWSoMR_SCIHOHSP"
    "--start_time"
        help = "start time to use for background. Can give yyyy-mm-ddThh:mm:sec:fracsec"
        default="MapTime"
    "--nRuns"
        help = "Number of runs to write. Will be checked to ensure it is less than total size of background design."
        arg_type=Int
        default=100
end

args = parse_args(s)

## CHECK IF PARAM FILE EXISTS
fileParam = args["fileParam"]

# if !isfile(fileParam) # THIS IS ATROCIOUS! IT IS NOT CASE SENSITIVE. 
if !isfile(realpath(fileParam))
    error("Enter a valid param file as argument")
else
    println("Valid PARAM file provided")
end

## PROCESS BACKGROUND
md = args["md"]
fileMap = args["fileMap"]
startTime = args["start_time"]

fileBackground = args["fileBackground"]
XBackground = CSV.read(fileBackground, DataFrame)

nBackground = size(XBackground, 1)
nRunsToWrite = args["nRuns"]

@assert nRunsToWrite <= nBackground

insertcols!(XBackground, 1, :map=> fileMap)
insertcols!(XBackground, 2, :model=>md)

colNamesBackground = [
                    "map",
                    "model",
                    "BrFactor", 
                    "PoyntingFluxPerBSi", 
                    "LperpTimesSqrtBSi"
                    ]

rename!(XBackground, colNamesBackground)


## START WRITING TO TEMP FILE
# Create temporary file path and IO
(tmppath, tmpio) = mktemp()

# Get filename for output
paramListFileName = args["fileOutput"]

# Track which file was used to read the runs!
write(tmpio, "# Background design: " * fileBackground * "\n")

write(tmpio, "\n # selected backgrounds = ")

write(tmpio, "\nselected run IDs = 1-$(nRunsToWrite)\n")
write(tmpio, "\n#START\n")
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

    # Here we will put conditional to write startTime or have it not appear in the param list (revert to MapTime)
    if startTime == "MapTime"
        write(tmpio, 
        string(count) 
        * " " 
        * stringToWrite
        * "param=$(basename(realpath(fileParam)))" 
        * "\n")
    else
        write(tmpio, 
        string(count) 
        * " time=$(startTime)   " 
        * stringToWrite 
        * "param=$(basename(realpath(fileParam)))"
        * "\n")
    end

end
println("Wrote background runs")

## GREP FROM PARAM FILE!
colNamesToCheck = colNamesBackground[3:5]

# The o/p of the run command acts as a preliminary comparison with Param file.
println("The PARAM file gives the following results when checking keywords:")
# run(`grep "$(colNamesToCheck[1])""\|""$(colNamesToCheck[2])""\|""$(colNamesToCheck[3])" $fileParam`)
for i in 1:length(colNamesToCheck)
    run(`grep "$(colNamesToCheck[i])" $fileParam`)
end

# close or flush the temporary IO stream
flush(tmpio)

# Move the temporary file (src) to appropriate location (dst), force=true overwrites dst if it already exists 
mv(tmppath, paramListFileName, force=true)

# confirmation message
println("Successfully wrote runs to file " * paramListFileName)
println("Make suitable modifications as necessary to $fileParam based on the output")



