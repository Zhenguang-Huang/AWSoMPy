# Write a set of "template" background runs (40 in total for now) for multiple Carrington Rotations, using FactorB0, PoyntingFluxPerBSi, LperpTimesSqrtBSi and StochasticExponent

using DataFrames
using Printf
using Dates
using CSV
using Distributions
using Random

nRuns = 20

using RCall

@rput nRuns

R"""
library(MaxPro)
nRunsInitial <- 80
pContinuous <- 4
IDContinuous <- MaxProLHD(n = nRunsInitial, p = 4)$Design
IDMaxPro <- MaxProQQ(IDContinuous, p_nom = 0)
"""

@rget nRunsInitial
@rget pContinuous
@rget IDContinuous
@rget IDMaxPro

XBest = IDMaxPro[:Design]

lbBg = [0.54, 0.3e6, 0.3e5, 0.1]
ubBg = [2.7, 1.1e6, 3e5, 0.34]

c1 = XBest[:, 1] * (ubBg[1] - lbBg[1]) .+ lbBg[1]
c2 = XBest[:, 2] * (ubBg[2] - lbBg[2]) .+ lbBg[2]

# solarMaxConstraint = (c1 .* c2) .<= 9e5
solarMinConstraint = (c1 .* c2 ) .<= 1.2e6
# we relax the constraint to 1.2e6 for both new events we write, namely, 
# 1. 2010-04-03 CME - CR2095
# 2. 2023-04-21 CME - CR2270
# This is to create a pilot study where designs accomodate larger Poynting Flux values. 

XConstrainedMax = XBest[solarMinConstraint, :]
XConstrainedMax = XConstrainedMax[1:nRuns, :]

colNames = ["FactorB0", "PoyntingFluxPerBSi", "LperpTimesSqrtBSi", "StochasticExponent"]

XMaxScaled = XConstrainedMax .* (ubBg' - lbBg') .+ lbBg'

XDesignMax = DataFrame(XMaxScaled, :auto)
# XDesignMax = DataFrame(XMaxScaled)
rename!(XDesignMax, colNames)

# CSV.write("./output/multipleCRDesignFiles/BgParams40Runs.csv", XDesignMax)

# write above as a param list
(tmppath, tmpio) = mktemp()
write(tmpio, "selected run IDs = 1-$(size(XMaxScaled, 1))\n")
write(tmpio, "\n#START\n")
write(tmpio, "ID   params\n")

for i in 1:size(XMaxScaled, 1)
    write(tmpio, string(i) * "\t\t" * "map=\t\t" * "model=AWSoM2T\t\t" * colNames[1] * @sprintf("=%.4f\t\t", XMaxScaled[i, 1]) * colNames[2] * @sprintf("=%e\t\t", XMaxScaled[i, 2]) * colNames[3] * @sprintf("=%e\t\t", XMaxScaled[i, 3]) * colNames[4] * @sprintf("=%.4f\t\t", XMaxScaled[i, 4]) * "realization=[]\n")
end

flush(tmpio)
mv(tmppath, "/Users/ajivani/Desktop/Research/SWMFSOLAR/ParamListScripts/output/param_list_bg_template_CR_2095_2270.txt", force=true)


