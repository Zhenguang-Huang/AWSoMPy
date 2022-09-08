## DESCRIPTION:

# 1) Generate param_list with background and restart - read background runs csv, restart runs csv as well as an EEGGL Params list
# 2) Convert: CSV --> DataFrame --> Dictionary with Keys equal to column names and values equal to param value for that run ---> append `key = value`
# to a string and write string to a file ---> write final list with appropriate date at the end.
# 3) Use supplied path for PARAM.in file and compare to make sure that the appropriate keyword is being written.

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

# nb+1  restart=run***  Radius=***  BStrength=***   ApexHeight=***  OrientationCme=*** LatitudeCme=***  LongitudeCme=***
# nb+2  restart=run***  Radius=***  BStrength=***   ApexHeight=***  OrientationCme=*** LatitudeCme=***  LongitudeCme=***
# (same up to nb + nr runs)
# nb+nr restart=run***  Radius=***  BStrength=***   ApexHeight=***  OrientationCme=*** LatitudeCme=***  LongitudeCme=***


## LOAD PACKAGES
using CSV
using DataFrames
using IterTools
using Printf
using Dates
using DelimitedFiles
using ArgParse

## PARSE ARGUMENTS
s = ArgParseSettings(
    description="Generate run list for background and restart")
@add_arg_table s begin
    "--fileEEGGL"
        help = "Path to load EEGGL Params from."
        arg_type = String
        # default = "./output/restartRunDesignFiles/CR2192/EEGGLParams_CR2192.txt"
        default = "./ParamListScripts/output/restartRunDesignFiles/CR2154/EEGGL_Params_CR2154_20220908.txt"
    "--fileBackground"
        help = "Path to load background wind runs from."
        arg_type = String
        # default = "./output/restartRunDesignFiles/CR2192/X_background_CR2192_2022_02_14.csv"
        default = "./ParamListScripts/output/restartRunDesignFiles/CR2154/X_background_CR2154.csv"
    "--fileRestart"
        help = "Path to load restart runs from."
        arg_type = String
        # default = "./output/restartRunDesignFiles/CR2192/X_design_CR2192_2022_03_21.csv"
        default = "./ParamListScripts/output/restartRunDesignFiles/CR2154/X_design_CR2154_2022_09_07.csv"
    "--fileOutput"
        help = "Give path to file where we wish to write param list"
        default = "./ParamListScripts/output/param_list_" * Dates.format(Dates.now(), "yyyy_mm_dd") * ".txt"
    "--fileParam"
        help = "Give path to correct PARAM file (specify in restarts AND check for keywords"
        default = "./Param/PARAM.in.awsom.CME"
    "--fileMap"
        help = "Give filename of map to be used, for eg: `ADAPT_41_GONG_CR2161.fts`."
        # default = "ADAPT_41_GONG_CR2192.fts"
        default = "ADAPT_41_CR2154.fts"
    "--mg"
        help = "Magnetogram to use, for example, GONG."
        default = "ADAPT"
    "--cr"
        help = "CR to use eg: 2152."
        arg_type = Int
        default = 2154
    "--md"
        help = "Model to use, for example AWSoM, AWSoMR, AWSoM2T."
        # default = "AWSoM"
        default = "AWSoM2T"
    "--start_time"
        help = "start time to use for background. Can give yyyy-mm-ddThh:mm:sec:fracsec"
        default="MapTime"
end

args = parse_args(s)

## CHECK IF PARAM FILE EXISTS
fileParam = args["fileParam"]
if !isfile(fileParam)
    error("Enter a valid param file as argument")
end

## EXTRACT AND PROCESS ARGUMENTS FOR BACKGROUND
mg = args["mg"]
cr = args["cr"]
md = args["md"]

fileBackground = args["fileBackground"]
XBackground = DataFrame(CSV.File(fileBackground))

nBackground = size(XBackground, 1)

fileMap = args["fileMap"]

insertcols!(XBackground, 1, :map=> fileMap)
insertcols!(XBackground, 2, :model=>md)

colNamesBackground = [
                    "map",
                    "model",
                    "FactorB0", 
                    "PoyntingFluxPerBSi", 
                    "LperpTimesSqrtBSi"
                    ]

rename!(XBackground, colNamesBackground)


## EXTRACT AND PROCESS ARGUMENTS FOR RESTART
fileRestart = args["fileRestart"]
XRestart = DataFrame(CSV.File(fileRestart))
if "Column1" in names(XRestart) 
    deletecols!(XRestart, "Column1")
end

colNamesRestart = [
                "RelativeStrength",
                "CmeRadius",
                "DeltaOrientation",
                "ApexCoeff",
                "iHelicity",
                "restartdir",
                # "realization" # valid for CR2192 only (as of now)
                ]   # give column names for data frame (can be redundant if names are already correct)

rename!(XRestart, colNamesRestart)


## EXTRACT AND PROCESS EEGGL PARAMS
fileEEGGL = args["fileEEGGL"]

"""
    function getEEGGLParams(f::IOStream)
Processes EEGGL Params, and returns a dictionary with keys corresponding to keywords in file, eg: "LatitudeCme", "TypeCme" and so on.
Typically called using `open(getEEGGLParams, filenameEEGGL)`.
"""
function getEEGGLParams(f::IOStream)
    println("Opened EEGGL file")
    eegglParams = Dict()
    
    lines = readlines(f)

    header = findfirst.("#CME", lines) # find occurrence of #CME
    iBegin = findall(!isnothing, header)
    

    if length(iBegin) == 1 # identified unique header in file
        iParamStart = iBegin[1] + 1
    else
        error("Recheck file for correct formatting i.e. #CME followed by list of params")
    end

    # Extract param names and values and store them in `eegglParams`
    for line in lines[iParamStart:end]
        strValue, nameEEGGL = split(line)
        eegglParams[nameEEGGL] = strValue
    end 

    println("Got EEGGL Parameters")
    return eegglParams
end

eegglParams = open(getEEGGLParams, fileEEGGL) # Using `open` with user-defined function to operate on file handle.

# Parse values for the event specific parameters 
Radius_EEGGL        = parse(Float64, eegglParams["Radius"])
B_EEGGL             = parse(Float64, eegglParams["BStrength"])
Orientation_EEGGL   = parse(Float64, eegglParams["OrientationCme"])

# Parse LatitudeCme and LongitudeCme and write to all the restarts.
LatitudeCme         = parse(Float64, eegglParams["LatitudeCme"])
LongitudeCme        = parse(Float64, eegglParams["LongitudeCme"])


## FORMULAE FOR PROCESSING ORIGINAL INDEPENDENT DESIGN VARIABLES
# Corrected formulae:
# 1) Radius    = CmeRadius - produce this first
# 2) BStrength = RelativeStrength * |B_EEGGL| * Helicity * (Radius_EEGGL / Radius)
# 3) ApexHeight = Radius * ApexCoeff
# 4) Orientation = Orientation_EEGGL + DeltaOrientation

# Deliberately splitting up insertion for radius and others, since others are dependent on radius. 
# (more robust to changes in calculation of Radius)
insertcols!(
            XRestart,
            1, 
            :Radius         => XRestart.CmeRadius
        )

insertcols!(
            XRestart, 
            2,
            :BStrength      => (abs(B_EEGGL) * Radius_EEGGL)  .* (XRestart.RelativeStrength ./ XRestart.Radius),
            :ApexHeight     => XRestart.Radius .* XRestart.ApexCoeff,
            :OrientationCme => XRestart.DeltaOrientation .+ Orientation_EEGGL
            )

# Discard distribution columns now, we don't want to write them to file!
deletecols!(
            XRestart, 
            ["RelativeStrength",
            "CmeRadius",
            "DeltaOrientation",
            "ApexCoeff",
            # "iHelicity",
            # "realization"
            ]
            )

# CR2154 did not vary realizations, CR2161 and CR2192 already have it incorporated into the XDesign file!!
# bg_realization_lookup = Dict([11, 7, 17, 6, 5, 3, 16, 1, 2, 8] .=> [4, 4, 9, 9, 5, 2, 12, 5, 2, 4])

# valid for CR2192
# REALIZATIONS = [[i] for i in XRestart.realization]
# insertcols!(XRestart,
#             6,
#             :REALIZATIONS => REALIZATIONS)
# deletecols!(XRestart, :realization)
# rename!(XRestart, :REALIZATIONS => :realization)



# Small addition: Also save above as a csv because its useful for future processing 
# (param list is not as easily readable into array like form).
CSV.write("./ParamListScripts/output/restartRunDesignFiles/CR2154/X_restart_CME_2022_09_08.csv", XRestart)

startTime = args["start_time"]

# count number of restarts
nRestart = size(XRestart, 1)

# start restart numbering from nBackground + 1
runIDRange = (nBackground + 1):(nBackground + nRestart)


## START WRITING TO TEMP FILE
# Create temporary file path and IO
(tmppath, tmpio) = mktemp()

# Get filename for output
paramListFileName = args["fileOutput"]

# Write EEGGL params in header
write(tmpio, "#CME\n")
for (key, value) in eegglParams
    write(tmpio, "# " * value * "           " * key * "\n")
end    

# Track which files the runs were read from.
write(tmpio, "# EEGGL File: " * fileEEGGL * "\n")
write(tmpio, "# Background design: " * fileBackground * "\n")
write(tmpio, "# Restart design: " * fileRestart * "\n")

write(tmpio, "\n # selected backgrounds = ")

write(tmpio, "\nselected run IDs = 1-$(size(XRestart, 1) + nBackground)\n")
write(tmpio, "\n#START\n")
write(tmpio, "ID   params\n")

# Loop through DataFrame for background
for count = 1:size(XBackground, 1)

    dfParams = XBackground[count, Not(["map", "model"])]
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



# Revert to usual style of writing restarts since allocation of restart dir is already in the file we read in, and is not done ad hoc anymore.
for count = 1:size(XRestart, 1)
    dfParams = XRestart[count, Not("restartdir")] # don't write restartdir as an integer directly.
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
        elseif value in [-1, 1]
            appendVal = @sprintf("%s=%d     ", key, value)
        else
            appendVal = @sprintf("%s=%.4f    ", key, value)
        end
        stringToWrite = stringToWrite * appendVal
    end

    write(tmpio, 
        string(runIDRange[count]) * " " * "restartdir=" 
        * @sprintf("run%03d_", XRestart[count, "restartdir"]) * md * "      param=$(basename(realpath(fileParam)))      " 
        * " LongitudeCme=$(LongitudeCme)    " * " LatitudeCme=$(LatitudeCme)      "
        * stringToWrite * "\n"
        )
end
# end for loop

# colNamesToCheck = names(XRestart[!, Not(["realization", "restartdir"])])
colNamesToCheck = names(XRestart[!, Not(["restartdir"])])
# The o/p of the run command acts as a preliminary comparison with Param file.
println("The PARAM file gives the following results when checking keywords:")
for i in 1:length(colNamesToCheck)
    run(`grep "$(colNamesToCheck[i])" $fileParam`)
end

## WRITE TO PERMANENT FILE
# close or flush the temporary IO stream
flush(tmpio)

# Move the temporary file (src) to appropriate location (dst), force=true overwrites dst if it already exists 
mv(tmppath, paramListFileName, force=true)

# confirmation message
println("Wrote restart runs")
println("Successfully wrote runs to file " * paramListFileName)
