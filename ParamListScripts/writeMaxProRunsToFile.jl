using CSV
using DataFrames
using Printf
using Dates
using Distributions
using Random 

# Specify map model and CR
mg = "ADAPT"
cr = 2208
md = "AWSoM"


XMaxPro = CSV.read("./output/bgDesignFiles/X_background_CR$(cr)_updated.csv", DataFrame)

# Read in csv file for MaxPro design (file generated from RStudio script) and convert to DataFrame
# XMaxPro = CSV.File("./SampleOutputs/2021_04_09_X_design_MaxPro_ADAPT_AWSoM.csv") |> DataFrame
# XMaxPro = CSV.File("./output/X_design_MaxPro_ADAPT_AWSoM.csv") |> DataFrame
# XMaxPro = XMaxPro[1:200, 2:end]

# REALIZATIONS_ADAPT = floor.(XMaxPro[:, :REALIZATIONS_ADAPT] * 11 .+ 1) .|> Int
REALIZATIONS_ADAPT = XMaxPro[!, "realization"]
REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(XMaxPro, 1)]
select!(XMaxPro, Not("realization"))
# deletecols!(XMaxPro, :REALIZATIONS_ADAPT)
insertcols!(XMaxPro, 9, :realization=>REALIZATIONS_ADAPT)

# Add columns for writing out .fits fileName and model
insertcols!(XMaxPro, 1, :map=>string(mg, "_CR", "$(cr)",  ".fits"))
insertcols!(XMaxPro, 2, :model=>md)

colNames = ["map",
            "model",
            "FactorB0", 
            "nChromoSi_AWSoM", 
            "PoyntingFluxPerBSi", 
            "LperpTimesSqrtBSi", 
            "StochasticExponent", 
            "rMinWaveReflection",
            "pfss",
            "UseSurfaceWaveRefl",
            "realization"
            ]   # give column names for data frame
rename!(XMaxPro, colNames)

# change columns for pfss and UseSurfaceWaveRefl
# Note: for PFSS - 1 = HARMONICS, 2 = FDIPS, for UseSurfaceWaveRefl, 1 = TRUE, 2 = FALSE

pfss_t = XMaxPro.pfss
UseSurfaceWaveRefl_t = XMaxPro.UseSurfaceWaveRefl

pfss = replace(pfss_t, 1=>"HARMONICS", 2=>"FDIPS")
UseSurfaceWaveRefl = replace(UseSurfaceWaveRefl_t, 1=>"T", 2=>"F")

select!(XMaxPro, Not(:pfss))
select!(XMaxPro, Not(:UseSurfaceWaveRefl))
insertcols!(XMaxPro, :pfss=>pfss, :UseSurfaceWaveRefl=>UseSurfaceWaveRefl)


# Sspecify full file name for event_list
currDateTime = Dates.now()
currDTString = Dates.format(currDateTime, "yyyy_mm_dd")
fileName = "param_list_"* "CR$(cr)_" * "updated" * ".txt"

# Extract keys and values from DataFrame and write as strings to event_list_file
(tmppath, tmpio) = mktemp()
write(tmpio, "selected run IDs = 1-$(size(XMaxPro, 1))\n")
write(tmpio, "#START\n")
write(tmpio, "ID   params\n")

# Loop through DataFrame
for count = 1:size(XMaxPro, 1)
    dfCount = XMaxPro[count, 3:end]
    dictCount = Dict(names(dfCount) .=> values(dfCount))
    stringToWrite = ""
    
    dfCountBlock = XMaxPro[count, 1:2]
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
mv(tmppath, joinpath("./output", fileName), force=true)