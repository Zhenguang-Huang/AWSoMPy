using IterTools
using DataFrames
using Printf
using Dates

# FORMAT FOR WRITING EVENT_LIST files. 

# this script writes list for baseline runs to a .txt file in appropriate format as given below:
# IMPORTANT: the lines 'selected run IDs = *' and '#START' are required.
# Accepted key word in params:
#  map, which specifies the filename of the magnetogram
#  pfss, which specifies the PFSS solver, either HARMONICS or FDIPS
#  time, which specifies the start time of the simulation
#  model, which specifies the module used, either AWSoM or AWSoMR. AWSoM and AWSoMR could not be selected at the same time.
#  realization, which specifies the realization for ADAPT maps. The format is similar as run IDs.
#  add, which specifies any command to be turned on. This requires that the command is already in the PARAM.in/FDIPS.in/HARMONICS.in.
#  	And it can turn on multiple commands (separated by comma, NO SPACE IN BWTWEEN), e.g., add=HARMONICSFILE,HARMONICSGRID
#  rm, which specifies any command to be turned off. This requires that the command is already in the PARAM.in/FDIPS.in/HARMONICS.in.
#  	And it can turn off multiple commands (separated by comma, NO SPACE IN BWTWEEN), e.g., rm=HARMONICSFILE,HARMONICSGRID
#  any one command from the PARAM.in file (case sensitive), e.g., UnitB, StochasticExponent.
#      No space between the command and the value.
#
# Choose the run IDs, can be multiple IDs, e.g., 1,3,4,5-10,16
# selected run IDs = 1,3

# #START
# ID	params
# 1	map=GONG_CR2208.fits  model=AWSoM
# ....
# 5	map=ADAPT_CR2208.fits model=AWSoM  realization=[1]
# 6	map=ADAPT_CR2209.fits model=AWSoM  realization=[1]
# 7	map=ADAPT_CR2152.fits model=AWSoM  realization=[1]


# fetch current date and time and add to generated file
currDateTime = Dates.now()
currDTString = Dates.format(currDateTime, "yyyy_mm_dd_HH_MM_SS")

# specify full file name
# fileName = currDTString * "event_list.txt"
fileName = "baseline_event_list_3Models.txt"

# make dataframe from all combinations of params and write rows of dataframe to lines of text file


# we can add more entries in mg and cr if required, code handles all combinations
mg = ["GONG", "ADAPT"]
cr = [2208, 2209, 2152, 2154]
md = ["AWSoM", "AWSoMR", "AWSoM2T"]

designMatrix  = []
using IterTools
for p in product(mg, cr, md) # product iterates over all combinations of its arguments
    push!(designMatrix, p)
end

dfDesign = DataFrame(designMatrix)          # make dataframe out of array of tuples generated from above loop
colNames = ["magnetogram", "cr", "model"]   # give column names for data frame
rename!(dfDesign, colNames)

# Create column for model based on mg and cr
insertcols!(dfDesign, 2, :map => string.(dfDesign[:magnetogram], "_CR", dfDesign[:cr],  ".fits"))
deletecols!(dfDesign, [1, 3])

io = open(fileName, "w")
write(io, "selected run IDs = 1-$(size(dfDesign, 1))\n")
write(io, "#START\n")
write(io, "ID   params\n")

for count = 1:size(dfDesign, 1)
    dfCount = dfDesign[count, :]
    dictCount = Dict(names(dfCount) .=> values(dfCount))
    stringToWrite = ""
    for (key, value) in dictCount
        appendVal = string(key, "=", value, " ")
        stringToWrite = stringToWrite * appendVal
    end
    write(io, string(count) * " " * stringToWrite * "\n")
end
close(io)

# insert realizations at ADAPT maps
realization_idx = 1 # some number between 1 and 12 for baseline runs (fixed here, to be varied in later event lists)
(tmppath, tmpio) = mktemp() ;
open(fileName) do f
    for line in eachline(f, keep=true)
        if occursin("map=ADAPT", line)
            line = line[1:end-1]
            line = line * "realization=[$(realization_idx)]\n"
        end
    write(tmpio, line)
    end
end
close(tmpio); 
mv(tmppath, fileName, force=true)
