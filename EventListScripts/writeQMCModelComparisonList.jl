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

seedPythonQMC = 20210703
# Lines in Python
# seed = 20210703
# sobol_lattice = qp.Sobol(dimension = 6, 
#                          seed = seed,
#                         )
# np.random.seed(seed)

if md == "AWSoMR"
    colNames = ["map",
            "model",
            "BrMin", 
            "BrFactor", 
            "PoyntingFluxPerBSi", 
            "LperpTimesSqrtBSi", 
            "StochasticExponent",
            "rMin_AWSoMR",
            "rMinWaveReflection",
            "pfss",
            "UseSurfaceWaveRefl",
            "realization"
            ]   # give column names for data frame
else
    colNames = ["map",
            "model",
            "BrMin", 
            "BrFactor", 
            "PoyntingFluxPerBSi", 
            "LperpTimesSqrtBSi", 
            "StochasticExponent",
            "nChromoSi_AWSoM",
            "rMinWaveReflection",
            "pfss",
            "UseSurfaceWaveRefl",
            "realization"
            ]   # give column names for data frame
end

nRuns = 100

# Specify full file name for event_list
currDateTime = Dates.now()
currDTString = Dates.format(currDateTime, "yyyy_mm_dd_HH_MM_SS")


if cr == 2152
    data, columns = readdlm(joinpath("./SampleOutputs/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solar" * "Max_" * "$(md)" * "_reducedThreshold.txt"), 
                            header=true)
    data = data[1:nRuns, 2:end]
    columns = columns[1:end-1]
    XDesign = DataFrame(data)
    rename!(XDesign, vec(columns))
    fileName = currDTString * "_event_list_SolarMax_" * mg * "_" * md * "_" * "CR$(cr)" * ".txt"
elseif cr == 2208
    data, columns = readdlm(joinpath("./SampleOutputs/QMC_Data_for_event_lists/revised_thresholds/", "X_design_QMC_masterList_solar" * "Min_" * "$(md)" * "_reducedThreshold.txt"), 
                            header=true)
    data = data[1:nRuns, 2:end]
    columns = columns[1:end-1]
    XDesign = DataFrame(data)
    rename!(XDesign, vec(columns))
    fileName = currDTString * "_event_list_SolarMin_" * mg * "_" * md * "_" * "CR$(cr)" * ".txt"
end


REALIZATIONS_ADAPT = floor.(XDesign[:, :realization] * 11 .+ 1) .|> Int
REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(XDesign, 1)]
deletecols!(XDesign, :realization)
insertcols!(XDesign, 10, :realization=>REALIZATIONS_ADAPT)

# Add columns for writing out .fits fileName and model
insertcols!(XDesign, 1, :map=>string(mg, "_CR", "$(cr)",  ".fits"))
insertcols!(XDesign, 2, :model=>md)

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


# Extract keys and values from DataFrame and write as strings to event_list_file
(tmppath, tmpio) = mktemp()
write(tmpio, "# seed used in Python QMCPY = $(seedPythonQMC)\n")
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


