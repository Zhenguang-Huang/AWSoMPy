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

nRuns = 100

# Specify full file name for event_list
currDateTime = Dates.now()
currDTString = Dates.format(currDateTime, "yyyy_mm_dd_HH_MM_SS")


if cr == 2152
    XDesign = DataFrame(CSV.File(joinpath("./SampleOutputs/QMC_Data_for_event_lists/", "X_design_QMC_reducedSpace_solar" * "Max" * ".csv")))
    deletecols!(XDesign, "Column1")
    XDesign = XDesign[1:nRuns, :]
    fileName = currDTString * "_event_list_SolarMax_" * mg * "_" * md * "_" * "CR$(cr)" * ".txt"
elseif cr == 2208
    XDesign = DataFrame(CSV.File(joinpath("./SampleOutputs/QMC_Data_for_event_lists/", "X_design_QMC_reducedSpace_solar" * "Min" * ".csv")))
    deletecols!(XDesign, "Column1")
    XDesign = XDesign[1:nRuns, :]
    fileName = currDTString * "_event_list_SolarMin_" * mg * "_" * md * "_" * "CR$(cr)" * ".txt"
end

if md == "AWSoMR"
    REALIZATIONS_ADAPT = floor.(XDesign[:, :realization] * 11 .+ 1) .|> Int
    REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(XDesign, 1)]
    deletecols!(XDesign, :realization)
    insertcols!(XDesign, 5, :realization=>REALIZATIONS_ADAPT)

    colNames = ["map",
            "model",
            "BrFactor", 
            "PoyntingFluxPerBSi", 
            "LperpTimesSqrtBSi", 
            "rMin_AWSoMR",
            "realization",
            "pfss", 
            "UseSurfaceWaveRefl",
            ]   # give column names for data frame
else
    REALIZATIONS_ADAPT = floor.(XDesign[:, :realization] * 11 .+ 1) .|> Int
    REALIZATIONS_ADAPT = [REALIZATIONS_ADAPT[i, :] for i in 1:size(XDesign, 1)]
    deletecols!(XDesign, :realization)

    # delete rMin_AWSoMR as well
    deletecols!(XDesign, :rMinAWSoMR)

    insertcols!(XDesign, 4, :realization=>REALIZATIONS_ADAPT)

    colNames = ["map",
            "model",
            "BrFactor", 
            "PoyntingFluxPerBSi", 
            "LperpTimesSqrtBSi", 
            "realization",
            "pfss",
            "UseSurfaceWaveRefl",
            ]   # give column names for data frame
end

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