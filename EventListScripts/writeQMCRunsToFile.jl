using CSV
using DataFrames
using IterTools
using Printf
using Dates
using Distributions
using DelimitedFiles


# Specify map model and CR
mg = "ADAPT"
cr = 2208
md = "AWSoM"


# Read in csv file for MaxPro design (file generated from RStudio script) and convert to DataFrame
# XMaxPro = CSV.File("./SampleOutputs/2021_04_09_X_design_MaxPro_ADAPT_AWSoM.csv") |> DataFrame

data, columns = readdlm("./SampleOutputs/X_design_QMC_ADAPT_AWSoM_solarMin.txt", header=true)
data = data[:, 2:end]
columns = columns[1:end-1]

XDesign = DataFrame(data)
rename!(XDesign, vec(columns))

REALIZATIONS_ADAPT = floor.(XDesign[:, :realization] * 11 .+ 1) .|> Int
REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(XDesign, 1)]
deletecols!(XDesign, :realization)
insertcols!(XDesign, 10, :realization=>REALIZATIONS_ADAPT)

# Add columns for writing out .fits fileName and model
insertcols!(XDesign, 1, :map=>string(mg, "_CR", "$(cr)",  ".fits"))
insertcols!(XDesign, 2, :model=>md)

colNames = ["map",
            "model",
            "BrMin", 
            "BrFactor",
            "nChromoSi_AWSoM", 
            "PoyntingFluxPerBSi", 
            "LperpTimesSqrtBSi", 
            "StochasticExponent", 
            "rMinWaveReflection",
            "pfss",
            "UseSurfaceWaveRefl",
            "realization"
            ]   # give column names for data frame
rename!(XDesign, colNames)

# change columns for pfss and UseSurfaceWaveRefl
# Note: for PFSS - 1 = HARMONICS, 2 = FDIPS, for UseSurfaceWaveRefl, 1 = TRUE, 2 = FALSE

pfss_t = XDesign.pfss
UseSurfaceWaveRefl_t = XDesign.UseSurfaceWaveRefl

pfss = replace(pfss_t, 1=>"HARMONICS", 2=>"FDIPS")
UseSurfaceWaveRefl = replace(UseSurfaceWaveRefl_t, 1=>"T", 2=>"F")

select!(XDesign, Not(:pfss))
select!(XDesign, Not(:UseSurfaceWaveRefl))
insertcols!(XDesign, :pfss=>pfss, :UseSurfaceWaveRefl=>UseSurfaceWaveRefl)


# Specify full file name for event_list
currDateTime = Dates.now()
currDTString = Dates.format(currDateTime, "yyyy_mm_dd_HH_MM_SS")
fileName = currDTString * "_event_list_SolarMin_" * mg * "_" * md * "_" * "CR$(cr)" * ".txt"


# Extract keys and values from DataFrame and write as strings to event_list_file
(tmppath, tmpio) = mktemp()
write(tmpio, "selected run IDs = 1-$(size(XDesign, 1))\n")
write(tmpio, "#START\n")
write(tmpio, "ID   params\n")

# Loop through DataFrame
for count = 1:size(XDesign, 1)
    dfCount = XDesign[count, 3:end]
    dictCount = Dict(names(dfCount) .=> values(dfCount))
    stringToWrite = ""
    
    dfCountBlock = XDesign[count, 1:2]
    dictCountBlock = Dict(names(dfCountBlock) .=> values(dfCountBlock))

    for (key, value) in dictCountBlock
        appendVal = @sprintf("%s=%s    ", key, value)
        stringToWrite = stringToWrite * appendVal
    end



    for (key, value) in dictCount
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

    write(tmpio, string(count) * " " * stringToWrite * "\n")
end
close(tmpio); 
mv(tmppath, joinpath("./SampleOutputs/", fileName), force=true)

 
