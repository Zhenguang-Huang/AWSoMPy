### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 933ae98e-d0eb-11ec-1ba6-2fc31d8c1510
begin
	using Pkg
	Pkg.activate("../Project.toml")

	using PolyChaos
	using LinearAlgebra
	using DelimitedFiles
	using StatsPlots
	using Plots
	using Plots.PlotMeasures
	using Printf

	using CSV
	using DataFrames

	using NetCDF
	using Dates

	using PlutoUI
end

# ╔═╡ dc90bbc7-c265-4850-9f13-71d9705d45be
begin
	using Revise
	include("/Users/ajivani/.julia/dev/GSA_CME/src/gsaUtilities.jl")
	include("../src/plotUtils.jl")
end

# ╔═╡ 23086bf0-54e0-4930-b161-5cca60e4166b
begin
	using JLD
	# save("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapUr2208.jld", "UrBootstrap", UrBootstrap)
	# save("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapNp2208.jld", "NpBootstrap", NpBootstrap)
end

# ╔═╡ 543596ec-a6e5-4779-a2a9-fea1ceb7a700
## INCREASE THE CELL WIDTH
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
  svg {
    width: 100%;
  }
</style>
"""

# ╔═╡ 83350690-3b47-4af7-aaed-474793c23219
md"""
### Load files for plot and gsa utils
"""

# ╔═╡ 6765dcad-b067-47de-98f4-d1eba31be765
md"""
### LOAD INPUT DATA
"""

# ╔═╡ 5ec433c9-0f37-4584-aace-7c1bec6fbf05
begin
	X_design = CSV.read("/Users/ajivani/Desktop/Research/MaxProDesignCME/designOutputs/X_background_CR2208_updated.csv", DataFrame)
	# rename!(X_design, :FactorBo => :FactorB0)
end

# ╔═╡ 003792f0-b399-4eba-8dd2-2da32b587219
begin
	lbBg = [0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1]
	ubBg = [2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2]
	
	paramsBgScaled = (X_design[!, 1:6] .- lbBg') ./ (ubBg' - lbBg')
end

# ╔═╡ 46168df1-54af-4547-99c8-06b42a4ac864
extrema(Matrix(paramsBgScaled); dims=1)[:]

# ╔═╡ 09e9a23f-7c39-4ce4-9f57-d1c3b71dd07c
with_terminal() do 
	ncinfo("../data/old_data/bg_CR2208.nc")
end

# ╔═╡ dfbaccaf-66af-43ea-88d8-a6e9764b146f
begin

	fn = "../data/old_data/bg_CR2208.nc" # change filename to reflect reorganization of data - bg_CR2208 now falls under old_data
	# fn = "../data/bg_CR2208.nc" 
	UrSim = ncread(fn, "UrSim")
	NpSim = ncread(fn, "NpSim")
	TSim  = ncread(fn, "TSim")
	BSim  = ncread(fn, "BSim")	

	UrObs = ncread(fn, "UrObs")
	NpObs = ncread(fn, "NpObs")
	TObs  = ncread(fn, "TObs")
	BObs  = ncread(fn, "BObs")	
	
	actualStartTime = ncgetatt(fn, "time", "actualStartTime")
	startTime = ncgetatt(fn, "time", "startTime")
	timeElapsed = Dates.Hour.(ncread(fn, "time"))
	times = timeElapsed .+ Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS")

	successfulRuns = ncgetatt(fn, "runs", "successfulRuns")
	runsToKeep     = ncgetatt(fn, "runs", "runsToKeep")
	
end

# ╔═╡ 18fb7539-a8aa-42b8-a78c-ece38b3b6174
successfulRuns

# ╔═╡ f785df1e-43df-4dcf-95d5-ce4d0565ad4a
runsToKeep

# ╔═╡ a20007c6-5c90-4fff-8618-9055ce884851
startTime

# ╔═╡ 5ab604d5-584c-4b25-9e31-39d6ae13749a
times

# ╔═╡ 3823f232-40bc-40c3-87ef-d8b6ba7ddd38


# ╔═╡ dde2906d-a892-48eb-abdf-836d2e555d22
md"""
### Plot sim and obs
"""

# ╔═╡ 13946121-5d6e-4370-97d5-888e66e4b3d9


# ╔═╡ e823c7bc-1b92-4397-b9fb-e29d0e8c0ac0
parse.(Int, ["2"])[:]

# ╔═╡ 332d1132-9de4-4908-8125-c0f1cb7d4277
# additionalExcluded = [5, 11, 14, 20, 23, 30, 31, 34, 39, 41, 42, 48, 49, 53, 54, 64, 65, 68, 69, 72, 74, 85, 88, 91, 93, 94, 103, 112, 117, 119, 137, 141, 149, 164, 174]
additionalExcluded = [114, 115, 152, 178]

# ╔═╡ 5f24f3ec-d63b-4030-90d4-e967f433e54e
findall(in([114, 178]), runsToKeep)

# ╔═╡ c18f5f64-72b9-4384-b1e6-858cfea0dd34
md"""
SIMID = $(@bind EachSimID MultiSelect([string.(successfulRuns[i]) => successfulRuns[i] for i in 1:length(successfulRuns)]))
"""

# ╔═╡ 444f5b42-fb30-47bc-9634-a69cfe13dcb2
EachSimID

# ╔═╡ 3441f2a4-c49e-4851-8409-575b7c319b5f


# ╔═╡ 5448968e-a994-497e-8428-829616a09eed
failedRuns = setdiff(1:200, successfulRuns)

# ╔═╡ 2517208e-d33b-4114-891d-bf26fa652073
#all runs to exclude, not counting failed
all2ExcludeIDs = [98, 152]

# ╔═╡ 178417f2-6130-4cc0-922c-541e1e5ecffb
NpObs

# ╔═╡ e3426359-25dd-4741-a2d3-1afbe0d77b05
success2KeepIDs = setdiff(1:200, [failedRuns; all2ExcludeIDs])

# ╔═╡ 8d6a5d8c-a0e4-458c-b69c-fc1d35031497
plot(UrSim[:, 152])

# ╔═╡ 8f18a9c8-68f8-4e0a-9c7d-47ed909344a7
plot(NpSim[:, 152])

# ╔═╡ fd112ea1-af42-49be-b5e0-fb10df932403
md"""
ToKeepSIMID = $(@bind ToKeepSims MultiSelect([string.(success2KeepIDs[i]) => success2KeepIDs[i] for i in 1:length(success2KeepIDs)]))
"""

# ╔═╡ c3fae2e1-a911-47c6-871a-79e016e47874


# ╔═╡ 04492c0c-b5ba-4884-bb3c-9dc089484691
maximum(UrSim[:, 152])

# ╔═╡ 5e2d1470-c487-46ed-b08d-af4a265e977d
minimum(UrSim[:, 119])

# ╔═╡ 630fcdb2-ef98-4ae8-ad15-3ebfe37c4e00
excludedRuns = setdiff(1:200, runsToKeep)

# ╔═╡ a7d9bc78-04bf-4404-83bc-db10c92e1cce
totalExcluded = unique([excludedRuns; additionalExcluded])

# ╔═╡ 9d9351e0-fce0-492c-a44c-3f2100c6cd00
actualStartTime

# ╔═╡ d12bc2f6-2a09-4b18-90e0-317da7dec7c2
"""
For L1, plot simulations and observations of different QoIs
"""
function plotExcludedSimObs(sim, obs, times, runs; 
                simIdx = 1:10,
                highlightIdx=1,
                palette=:Dark2_8,
                ylabel="QoI",
                ylims=(200, 900),
                tickInterval=12,
                title="Ur",
                plotLabels=false,
                legend=true,
                simAlpha=0.8,
                simWidth=1.5,
                dateFormat="dd-m HH:MM",
                dpi=500,
                subtractFactor=20,
                startTime="2015-03015T03:15:00"
                )
    if simIdx[1] isa String
        simIdx = parse.(Int, simIdx)
    end
	colIdx = deepcopy(simIdx)
    # colIdx = findall(in(simIdx .- subtractFactor), runsToKeep)
    nLines = length(simIdx)
    if plotLabels
        labelsVec = "run " .* string.(simIdx)
        lineLabels = reshape(labelsVec, 1, nLines)
        obsLabel = "OMNI"
    else
        lineLabels = ""
        obsLabel = ""
    end
    p = plot(1:length(times), sim[:, colIdx], 
    line=(simWidth), 
    line_z=(1:length(simIdx))',
    linealpha=simAlpha, 
    color=palette,
    label=lineLabels,
    dpi=dpi,
    )

    plot!(1:length(times), obs, 
    line=(:black, 2.5), 
    label=obsLabel,
    #minorgrid=true,
    yminorticks=10
    )

    obsTimeTicks = range(times[1], times[end], step=Hour(tickInterval))
    xticks  = findall(in(obsTimeTicks), times)
    xticklabels = Dates.format.(obsTimeTicks, dateFormat)

    # startTimeFormatted = Dates.format(Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS") - Minute(30),
                        # "dd-u-yy HH:MM:SS") 
    startTimeFormatted = Dates.format(Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS"),
                        "dd-u-yy HH:MM:SS") 
    plot!(xlabel="Start Time (" * startTimeFormatted * ")")
    plot!(ylabel=ylabel)
    plot!(xticks=(xticks, xticklabels))
    plot!(xminorticks=8),
    plot!(xlims=(1, length(times)))
    plot!(ylims=ylims)
    plot!(framestyle=:box)
    plot!(grid=false)
    plot!(legend=:outertopright),
    plot!(fg_legend=:false),
    plot!(colorbar=false)
    plot!(title=title)
    return p
end

# ╔═╡ 88fd5d74-437d-4ca9-a89f-95aa1dff0164
md"""
ExcludedSimIDs = $(@bind ExcludedSims MultiSelect([string.(excludedRuns[i]) => excludedRuns[i] for i in 1:length(excludedRuns)]))
"""

# ╔═╡ d6733c06-c6da-470e-bdba-6621816fc644
ExcludedSims

# ╔═╡ 5bd0e50a-6cac-471d-b29c-ab966777028b
md"""
### GSA
"""

# ╔═╡ 78eeb3d4-0528-4253-802f-d164e47e759e
begin
	X = Matrix(paramsBgScaled[runsToKeep, :])
	Y1 = Array{Float64, 2}(UrSim[:, runsToKeep]')
	Y2 = Array{Float64, 2}(NpSim[:, runsToKeep]')
	# Y = 
end

# ╔═╡ ee362fc8-1c74-4561-b1d8-db94d0648e96
# build coefficient matrix!
A = buildCoefficientMatrix(X; pceDegree=2)

# ╔═╡ bbdcc6ba-e6ae-470b-8b51-9ebbaa8b2a5f
begin
	gsaIndicesUr = gsa(X, Y1; regularize=false, pceDegree=2)
	gsaIndicesNp = gsa(X, Y2; regularize=false, pceDegree=2)
end

# ╔═╡ caa03923-fb76-4fbb-97fa-8180838df025
begin
	mainEffectsUr = processMainEffects(gsaIndicesUr)
	mainEffectsNp = processMainEffects(gsaIndicesNp)
end

# ╔═╡ 16f9b679-e8c5-4425-ab3e-ef8afd36f7f5
inputNames = names(paramsBgScaled)

# ╔═╡ 21b9bd18-4e4a-401a-b7a8-f361d73526b6


# ╔═╡ a0726b0a-5864-4323-869c-fb9d3b533473
md"""
Time = $(@bind timeIdx Select([string.(i) => i for i in 1:length(times)]))
"""

# ╔═╡ 60e83fd4-6cbe-4e4a-a525-2baf25246495
timeIdx

# ╔═╡ c3a0cceb-1c58-4463-9b3b-524fa0acd731
# Time = $(@bind timeIdx Slider(1:length(times), default=1, show_value=true))

# ╔═╡ 95e65a08-a149-42f7-a700-1f8364c3daec
interactionsUr = mean(gsaIndicesUr, dims=3)[:, :, 1]

# ╔═╡ 3e7bfb10-256e-43c6-994b-cfa9241e3dd8
interactionsNp = mean(gsaIndicesUr, dims=3)[:, :, 1]

# ╔═╡ 8906a937-3d18-49df-8c36-e4efe9146082


# ╔═╡ 8ce3aeb0-b7ac-4eb8-8ea8-0647c3860fc9
NpObs

# ╔═╡ eac76a23-99d9-4966-9e7b-5ba0635ef4b3
NpObs[544]

# ╔═╡ 6d6e2cf0-b40b-41d8-860b-46dcb1f2be0c
NpObsIdxToRemove = findall(x -> abs(x) >= 1000, NpObs)[1]

# ╔═╡ 9271189a-59d1-4da9-9264-61e26acef1f3
begin
	meanUr, stdUr = getConfidenceIntervals(X, Y1; regularize=false, pceDegree=2)
	meanNp, stdNp = getConfidenceIntervals(X, Y2; regularize=false, pceDegree=2)
end

# ╔═╡ efc84a10-aed4-4226-93f6-7110e1e68c30
plotMeanStd(Y1, meanUr, stdUr, UrObs, times, nSTD=2, trimIndices=(1, 577))

# ╔═╡ 58d87521-20fb-4bbb-88fe-cf154122609b
plotMeanStd(Y2, meanNp, stdNp, NpObs, times, nSTD=2, trimIndices=(1, 577), obsIdxToPlot=setdiff(1:577, 544))

# ╔═╡ f619c741-7928-4fe5-b09a-04cb923bcc59


# ╔═╡ 289204ea-3678-48af-9f62-95938ce61c8b


# ╔═╡ 285b7d3f-43c3-48d7-95ab-26b73f0d3faa
md"""
### Final Plots and Settings for solar minimum

Whatever is in this section will go into the paper, nothing else. So make sure its watertight

- Only removing runs that are bad for both Ur and Np simultaneously, not otherwise - will have to justify this properly. But its ok for now we just make figures, and we can redo the analysis if so required.

- Single regularization setting for both quantities

- Generate a test matrix of 1000 points, use all of them for showing uncertainties from the surrogate predictions. Show boxplots at selected points, else keep the +/- 2σ gap everywhere.

- Finally, get the sensitivity plots, try to plot only one half of the interaction matrix

- We may have to redo the bootstrapping plots as well.

- Make new scatterplots of full param space.

- Put all of this plus any other preprocessing needed in a separate repo 
"""

# ╔═╡ 721480ef-e711-43f0-9b33-8ec21ec0b8c1
md"""
Update: (2022/07/25) --> Load updated solar minimum data, and use new successful runs (199 out of 200) for calculating sensitivities!
"""

# ╔═╡ 76a454ef-ec9b-413d-a623-d072ab9c8b15
begin
	fnFinal = "../data/bg_cr2208_all_conservative_nonconservative.nc"
	UrSimFinal = ncread(fnFinal, "UrSim")
	NpSimFinal = ncread(fnFinal, "NpSim")
	TSimFinal  = ncread(fnFinal, "TSim")
	BSimFinal  = ncread(fnFinal, "BSim")	

	UrObsFinal = ncread(fnFinal, "UrObs")
	NpObsFinal = ncread(fnFinal, "NpObs")
	TObsFinal  = ncread(fnFinal, "TObs")
	BObsFinal  = ncread(fnFinal, "BObs")	
	
	actualStartTimeFinal = ncgetatt(fnFinal, "time", "actualStartTime")
	startTimeFinal = ncgetatt(fnFinal, "time", "startTime")
	timeElapsedFinal = Dates.Hour.(ncread(fnFinal, "time"))
	timesFinal = timeElapsed .+ Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS")

	successfulRunsFinal = ncgetatt(fnFinal, "runs", "successfulRuns")
	runsToKeepFinal     = ncgetatt(fnFinal, "runs", "runsToKeep")
end

# ╔═╡ 561074b1-2e96-4f30-8489-6a8d36948289
setdiff(1:200, successfulRunsFinal)

# ╔═╡ cc72a9bd-34a1-4998-b82f-8343f4b7cd06
excludeBothCriteriaOnly = deepcopy(failedRuns) # this includes failed runs too - 16, 50, 101, 126, 198

# ╔═╡ a07ff22d-d00b-4090-a93b-f0dd843174b3
md"""
Find successful run set
"""

# ╔═╡ 9bffc882-57b8-4b18-bce4-fc244a878159
# successBothCriteria = setdiff(1:200, excludeBothCriteriaOnly)
successBothCriteria = deepcopy(successfulRunsFinal)

# ╔═╡ e6967961-0347-496a-9a75-0da8f07fda72
md"""
Build coefficient matrix and solution matrices for Ur and Np on the basis of the above.
"""

# ╔═╡ 8c623cec-8b95-44ce-ab96-fab379c59808
begin
	XTrainFinal = Matrix(paramsBgScaled[successBothCriteria, :])
	# YTrainUr = Array{Float64, 2}(UrSim[:, successBothCriteria]')
	# YTrainNp = Array{Float64, 2}(NpSim[:, successBothCriteria]')
	
	# update Y with new data
	YTrainUr = Array{Float64, 2}(UrSimFinal[:, successBothCriteria]')
	YTrainNp = Array{Float64, 2}(NpSimFinal[:, successBothCriteria]')
end

# ╔═╡ cb17b891-77f8-4235-b9f1-25457b7eb4ff
XTrainFinal

# ╔═╡ 18056d05-e226-4e6c-9956-76fefe4dc8d6
# build coefficient matrix!
ATrainFinal = buildCoefficientMatrix(XTrainFinal; pceDegree=2)

# ╔═╡ d6440ae7-176b-4858-ba14-28a1c95bc1d2
md"""
Set regularization, and get beta values
"""

# ╔═╡ fcba86e3-c129-4e07-a5fc-36dc9cb9815f
lambdaUrFinal = 0.4

# ╔═╡ a78f0eb0-289a-4381-adcc-49ba3b1ca516
lambdaNpFinal = 5

# ╔═╡ 4960422c-d549-423d-9d2d-254851292a39
betaUrFinal = solveRegPCE(ATrainFinal, YTrainUr; λ=lambdaUrFinal)

# ╔═╡ 99ecd111-48b2-47a2-81dc-254d62892f10
betaNpFinal = solveRegPCE(ATrainFinal, YTrainNp; λ=lambdaNpFinal)

# ╔═╡ 47d46711-0d0b-4352-b6ec-e9315ca8d53a
begin
	gsaUrFinal = gsa(XTrainFinal, YTrainUr; regularize=true, pceDegree=2, lambda=lambdaUrFinal)
	gsaNpFinal = gsa(XTrainFinal, YTrainNp; regularize=true, pceDegree=2, lambda=lambdaNpFinal)
end

# ╔═╡ 4d59ddaf-6bbe-4e6e-ae06-5d0d3e4f3053
begin
	gsaMainUrFinal = processMainEffects(gsaUrFinal)
	gsaMainNpFinal = processMainEffects(gsaNpFinal)
end

# ╔═╡ 7676d4ef-4120-4379-9811-28c0f452f43c
begin
	XTestFinal = load("../../MaxProDesignCME/designOutputs/CR2208TestFinal.jld", "XTestFinal")[:, 1:6]
end

# ╔═╡ f8decbaf-57f5-40ce-b973-fa26932a947c
md"""
Optionally apply filter to only keep test points with a certain PoyntingFlux
"""

# ╔═╡ 572d8ee1-06b8-4d6d-9e7d-1ab4ff381af5
XTestFinalScaled = (XTestFinal[:, 1:6]) .* (ubBg' - lbBg') .+ lbBg'

# ╔═╡ 7f89925f-4d3e-45ed-9ff5-2e86d24017df
scatter(XTestFinalScaled[:, 1], XTestFinalScaled[:, 3])

# ╔═╡ 65e50610-3609-45fc-8de0-634c9309f518
ATestTemp = buildCoefficientMatrix(XTestFinal[:, 1:6]; pceDegree=2)

# ╔═╡ 532b17bb-c751-4802-939b-e4340479b947
PFThresholdFinal = 6e5

# ╔═╡ 8862154c-683b-4af6-8ee2-2b52be52579a
filterIdxATest = findall(x -> x <= PFThresholdFinal, XTestFinalScaled[:, 3])

# ╔═╡ 81880c2b-f93b-4dd6-a593-9317faf2b0f4
filterTest=false

# ╔═╡ 5ec50a1e-211b-4c25-8422-4774331c6a03
if filterTest
	ATestFinal = ATestTemp[filterIdxATest, :]
else
	ATestFinal = deepcopy(ATestTemp)
end

# ╔═╡ d3c2e722-5793-4562-9a79-1ca8b6990e31
begin
	ATestFinalFilteredCoeffs = ATestFinal[:, 2:end] # remove constant vector of ones
	ATestFinalFilteredC = ATestFinalFilteredCoeffs .- mean(ATestFinalFilteredCoeffs, dims=1)
	yPredNpFinal = betaNpFinal[1, :] .+ Matrix((ATestFinalFilteredC * betaNpFinal[2:end, :])')
	yPredUrFinal = betaUrFinal[1, :] .+ Matrix((ATestFinalFilteredC * betaUrFinal[2:end, :])')
end

# ╔═╡ ee54d9eb-be8b-4a76-9e45-fd6de6951b78
plot(yPredNpFinal, label="")

# ╔═╡ 444ca978-c7d7-4438-b8d1-5fb1401d7c1f
begin
	meanEmpiricalNpFinal = mean(yPredNpFinal; dims=2)
	stdEmpiricalNpFinal = std(yPredNpFinal; dims=2)[:]

	meanEmpiricalUrFinal = mean(yPredUrFinal; dims=2)
	stdEmpiricalUrFinal = std(yPredUrFinal; dims=2)[:]
end

# ╔═╡ f2d2d67d-925a-463a-8c5b-e4f3db1c2d9c
md"""
We will try a boxplot at selected points. Changing the bar width should hopefully enable properly spaced out boxes. 

Reference: [Stack Overflow](https://stackoverflow.com/questions/71456841/statsplots-boxplot-decrease-width-of-boxes)
"""

# ╔═╡ a5e1da76-cbf7-4010-83d7-f4e23b7fbd6d
md"""
Questions to address: Do we still want to keep 1.5 IQR? this is not necessarily relevant for highly asymmetric distribution. May just want to show violin plots instead but at fewer locations since it messes up width so badly.

can also try pyplot like functionality since we can apparently control the width of the violins.
"""

# ╔═╡ accfe8d2-062a-4a7f-a0f2-3b0f0e92afc7
md"""
Also **very important**: Make an alternative plot that doesn't show mean + / - 2sigma but just violin and boxplot combo.
"""

# ╔═╡ 427a28a3-901c-4f48-a3a8-bc62e59b4330
default(legendfontsize=10)

# ╔═╡ 69672719-b763-4cd3-a5d6-97bb74568fc7


# ╔═╡ 8335f6b5-49af-4b37-912f-ec0366dff307
function plotUncertainty(Y, meanPCE, stdPCE, obsData, timeData;
                    nSTD = 2,
                    ylims=(200, 900), 
                    ylabel="Ur",
                    trimIndices=(1, 720),
                    obsIdxToPlot=1:577,
					densitiesToPlot=1:30:557,
                    tickStep=84,
                    tickFormat="dd-mm",
                    dpi=600
                    )

    startTime, obsTimesTrimmed = processTimeInfo(timeData; trimIndices=trimIndices)
    obsTimeTicks = range(obsTimesTrimmed[1], 
                        obsTimesTrimmed[end], 
                        step=Hour(tickStep)
                        )
    xTicks = findall(in(obsTimeTicks), obsTimesTrimmed)
    labels = Dates.format.(obsTimeTicks, tickFormat)
    meanSim = mean(Y, dims=2)[:]
    # pCI = plot(Y', label="", alpha=0.4)
    # plot!(ylims=ylims)
    
    # plot!(meanSim, line=(:blue, 3), label="Sample Mean")

    if nSTD == 1
        plotLabel = "μ +/- σ for constructed PCE"
    else
        plotLabel = "μ +/- $(nSTD)σ for constructed PCE"
    end
    
    pCI = plot(meanSim, line=(:blue, 3), label="Sample Mean", dpi=dpi)
    plot!(meanPCE, grid=false, ribbon=nSTD*stdPCE,
        line=(:red, 3),
        # ribboncolor=:blues,
        fillalpha=0.5,
        xticks=(xTicks, labels),
        xlims=(1, length(obsTimesTrimmed)),
        label="μ +/- $(nSTD)σ for constructed PCE",
    )

	nPred = size(Y, 2)
	boxplot!(repeat(densitiesToPlot, outer=nPred), Y[densitiesToPlot, :][:], 
		label="", 
		bar_width=120/length(densitiesToPlot), 
		outliers=false, 
		fillcolor=:orange,
		fillalpha=0.7,
		whisker_range=1.5)
	
    # plot!(obsIdxToPlot, obsData[obsIdxToPlot], line=(:black, 3), label="OMNI")

		
    plot!(ylabel=ylabel)
    plot!(xlabel = "Start Time: $(Dates.format(startTime, "dd-u-yy HH:MM:SS"))")
    plot!(fg_legend=nothing)
    plot!(bg_legend=nothing)
	plot!(framestyle=:box)    	
	plot!(grid=true)
    return pCI
end

# ╔═╡ 874ae422-a71c-4d21-bbbc-80df197f8d40
begin
	plotUncertainty(yPredUrFinal, meanEmpiricalUrFinal, stdEmpiricalUrFinal, UrObs, ylabel="Uᵣ [km/s]", times, nSTD=2, trimIndices=(1, 577))
	plot!(guidefontsize=20)
	plot!(tickfontsize=15)
	plot!(legend=:topleft)
	plot!(left_margin=3mm)
	plot!(bottom_margin=3mm)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/cr2208_allData_uncertainty_boxplots_ur.png")
end

# ╔═╡ 8b7d6dbb-b8fa-4f24-a97b-5d7f6f0bb90f
begin
	plotUncertainty(yPredNpFinal, meanEmpiricalNpFinal, stdEmpiricalNpFinal, NpObs, ylabel="Nₚ [cm⁻³]", ylims=(-20, 120), times, nSTD=2, trimIndices=(1, 577), obsIdxToPlot=setdiff(1:577, 544))
	plot!(guidefontsize=20)
	plot!(tickfontsize=15)
	plot!(legend=:topleft)
	plot!(left_margin=3mm)
	plot!(bottom_margin=3mm)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/cr2208_allData_uncertainty_boxplots_np.png")
end

# ╔═╡ 899e37f9-a142-4298-bb74-4fc2f5ba6347


# ╔═╡ 5dda9b4a-410d-4158-b647-4f3b882a1786
# savefig(pUrIntMeanFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2208_allData_ur_ie_final.png")

# ╔═╡ e4986053-04ed-4011-bff6-c0b3a12ea608
# savefig(pNpIntMeanFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2208_allData_np_ie_final.png")

# ╔═╡ deb751b7-dcd5-4d47-9bfa-c90147db090c
md"""
Overlay successful runs with runs which are bad in Ur and Np _simultaneously_. Potentially better to remove this smaller set and easier to justify too? for further analysis!
"""

# ╔═╡ 9c7a6e2b-8121-4217-8d4f-8690a29fae4e
begin
	pScatterUncolored = scatter(X_design[:, "FactorB0"], X_design[:, "PoyntingFluxPerBSi"], 
								# zcolor=shiftWLRMSE.PTRMSE, 
								marker=(:black, :circle, 4), 
								xlabel="FactorB0", 
								ylabel="PoyntingFluxPerBSi",
								markerstrokewidth=0,
								label="",
								dpi = 300,
								grid=false
								)
	plot!(sort(X_design.FactorB0), 1.2e6 ./ (sort(X_design.FactorB0)), line=(:cyan, 2), label="FactorB0 x PoyntingFluxPerBSi= 1.2e6")
	plot!(ylims=(0.3e6, 1.1e6))
	plot!(guidefontsize=26)
	plot!(tickfontsize=21)
	plot!(framestyle=:box)
	plot!(left_margin=5mm)
	plot!(bottom_margin=5mm)
	plot!(right_margin=8mm)
	plot!(yticks=([4e5, 6e5, 8e5, 1e6], ["4.0e5", "6.0e5", "8.0e5", "1.0e6"]))
	plot!(thickness_scaling=1.1)
	plot!(size=(800, 600))
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/brpf_cr2208.png")
end

# ╔═╡ c4e91d3c-7abf-48bf-9d75-500ec6dccde0
begin
	LperpStoch = scatter(X_design[:, "LperpTimesSqrtBSi"], X_design[:, "StochasticExponent"], 
									# zcolor=shiftWLRMSE.PTRMSE, 
									marker=(:black, :circle, 4), 
									xlabel="LperpTimesSqrtBSi", 
									ylabel="StochasticExponent",
									markerstrokewidth=0,
									label="",
									dpi = 300,
									grid=false
									)
		plot!(guidefontsize=26)
		plot!(tickfontsize=21)
		plot!(framestyle=:box)
		plot!(left_margin=5mm)
		plot!(bottom_margin=5mm)
		plot!(right_margin=8mm)
		plot!(xticks=([5e4, 1e5, 1.5e5, 2e5, 2.5e5, 3e5], ["5.0e4", "1.0e5", "1.5e5", "2.0e5", "2.5e5", "3.0e5"]))
		plot!(size=(800, 600))
		# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/lpse_cr2208.png")
end

# ╔═╡ ea14c871-fa0e-4bc7-99ba-ebba0e4dbcb6
begin
	chromoLperp = scatter(X_design[:, "nChromoSi_AWSoM"], X_design[:, "LperpTimesSqrtBSi"], 
									# zcolor=shiftWLRMSE.PTRMSE, 
									marker=(:black, :circle, 4), 
									xlabel="nChromoSi_AWSoM", 
									ylabel="LperpTimesSqrtBSi",
									markerstrokewidth=0,
									label="",
									dpi = 300,
									grid=false
									)
		plot!(guidefontsize=26)
		plot!(tickfontsize=21)
		plot!(framestyle=:box)
		plot!(left_margin=5mm)
		plot!(bottom_margin=5mm)
		plot!(right_margin=8mm)
		plot!(xticks=([1e18, 2e18, 3e18, 4e18, 5e18], ["1.0e18", "2.0e18", "3.0e18", "4.0e18", "5.0e18"]))
		plot!(yticks=([5e4, 1e5, 1.5e5, 2e5, 2.5e5, 3e5], ["5.0e4", "1.0e5", "1.5e5", "2.0e5", "2.5e5", "3.0e5"]))
		plot!(size=(800, 600))
		# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/nclp_cr2208.png")

end

# ╔═╡ b0a9692d-727b-4176-ac6b-e8c78c5c11cc
begin
	LperpRMin = scatter(X_design[:, "LperpTimesSqrtBSi"], X_design[:, "rMinWaveReflection"], 
									# zcolor=shiftWLRMSE.PTRMSE, 
									marker=(:black, :circle, 4), 
									xlabel="LperpTimesSqrtBSi", 
									ylabel="rMinWaveReflection",
									markerstrokewidth=0,
									label="",
									dpi = 300,
									grid=false
									)
		plot!(guidefontsize=26)
		plot!(tickfontsize=21)
		plot!(framestyle=:box)
		plot!(left_margin=5mm)
		plot!(bottom_margin=5mm)
		plot!(right_margin=8mm)
		plot!(xticks=([5e4, 1e5, 1.5e5, 2e5, 2.5e5, 3e5], ["5.0e4", "1.0e5", "1.5e5", "2.0e5", "2.5e5", "3.0e5"]))
		plot!(size=(800, 600))
		
		# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/lprm_cr2208.png")
		
end

# ╔═╡ 0ba1fd65-ba7d-419e-b89a-93a314b99d66
begin
			# savefig(pScatterUncolored, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/brpf_cr2208.png")
			# savefig(LperpStoch, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/lpse_cr2208.png")
			# savefig(chromoLperp, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/nclp_cr2208.png")
			# savefig(LperpRMin, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/lprm_cr2208.png")
	
end

# ╔═╡ 7bbca210-6ee3-4ef3-8444-e7645f558aea
# plot these scatterplots with larger fonts. repeat the exercise for all other figures too.

# ╔═╡ 598c121a-171b-4422-80be-0fdbdbcee97e
begin
	pParamsUncolored = []
	for (i, name_x) in enumerate(inputNames[1:(end - 1)])
		for (j, name_y) in enumerate(inputNames[(i + 1):(end)])
			pScatter = scatter(X_design[!, name_x], X_design[!, name_y], 
				# zcolor=shiftWLRMSE.PTRMSE, 
				marker=(:black, :circle, 4), 
				xlabel=name_x, 
				ylabel=name_y,
				markerstrokewidth=0,
				label="",
				grid=false,
				dpi=300
			)
			plot!(framestyle=:box)
			push!(pParamsUncolored, pScatter)
		end
	end
	# plot(pParamsUncolored..., layout=(2, 5), size=(1400, 800))
end

# ╔═╡ 8e3eb976-9371-4b49-b7d6-2348098db36a
# begin
# [savefig(pParamsUncolored[i], 
# 	"/Users/ajivani/Downloads/Solar_Model_UQ_big/figures/doe/all_param_scatterplots/scatterplot_2208_" * @sprintf("%02d.png", i)) for i in 1:10]
# savefig(pScatterUncolored, "/Users/ajivani/Downloads/Solar_Model_UQ_big/figures/doe/all_param_scatterplots/scatterplot_2208_02.png")
# end

# ╔═╡ f9907461-9f63-4a40-b373-5caba8bf32ad
# plot(pParamsUncolored..., layout=(2, 5), size=(1400, 800))

# ╔═╡ 04eb7126-f28b-40a2-9408-304d3a3c7ef7
# savefig(pParamsUncolored[14], "/Users/ajivani/Downloads/Solar_Model_UQ_big/figures/doe/all_param_scatterplots/scatterplot_2208_14.png")

# ╔═╡ 128fae72-5eaa-48f9-b14b-486ac08a90c5
length(pParamsUncolored)

# ╔═╡ 8b4d22bb-3e73-4dd4-b24a-55b4067b22dc
inputNames

# ╔═╡ d33f3e17-a266-46f7-95c1-bb3421006ab2
@bind xParam Select(inputNames)

# ╔═╡ cfa5069c-377d-4cc1-aba4-ff891527ddd6
@bind yParam Select(inputNames)

# ╔═╡ ddf9acf5-f045-4250-88ff-94119d503cb8
begin
	pScatterGroupedSimFail = scatter(X_design[successBothCriteria, "FactorB0"], X_design[successBothCriteria, "PoyntingFluxPerBSi"], 
								marker=(:green, :circle, 4), 
								xlabel="FactorB0", 
								ylabel="PoyntingFluxPerBSi",
								markerstrokewidth=0,
								label="Runs used for PCE and GSA",
								dpi=300
								)
	# scatter!(X_design[excludeBothCriteriaOnly, "FactorB0"], X_design[excludeBothCriteriaOnly, "PoyntingFluxPerBSi"],
	# 	marker=(:blue, :circle, 4),
	# 	# xlabel=name_x,
	# 	# ylabel=name_y,
	# 	markerstrokewidth=0,
	# 	label="Removed from ensemble")
	failedFinal = X_design[setdiff(1:200, successfulRunsFinal), :]
	scatter!(failedFinal[!, "FactorB0"], failedFinal[!, "PoyntingFluxPerBSi"],
			marker=(:red, :circle, 4),
			# xlabel=name_x,
			# ylabel=name_y,
			markerstrokewidth=0,
			label="Failed simulations with no 1 AU results")
	plot!(sort(X_design.FactorB0), 1.2e6 ./ (sort(X_design.FactorB0)), line=(:cyan, 2), label="FactorB0 x PoyntingFluxPerBSi= 1.2e6")
	plot!(ylims=(0.3e6, 1.1e6))
	plot!(framestyle=:box)
	plot!(grid=false)
end

# ╔═╡ ba886e67-0679-44dd-8208-5c92d625f75a
begin
	pScatterGroupedSimFailAllParams = scatter(X_design[successBothCriteria, xParam], X_design[successBothCriteria, yParam], 
								marker=(:green, :circle, 4), 
								xlabel=xParam, 
								ylabel=yParam,
								markerstrokewidth=0,
								label="Runs used for PCE and GSA",
								dpi=300
								)
	# failedFinal = X_design[setdiff(1:200, successfulRunsFinal), :]
	scatter!(failedFinal[!, xParam], failedFinal[!, yParam],
			marker=(:red, :circle, 4),
			# xlabel=name_x,
			# ylabel=name_y,
			markerstrokewidth=0,
			label="Failed simulations with no 1 AU results")
	# plot!(sort(X_design.FactorB0), 1.2e6 ./ (sort(X_design.FactorB0)), line=(:cyan, 2), label="FactorB0 x PoyntingFluxPerBSi= 1.2e6")
	# plot!(ylims=(0.3e6, 1.1e6))
	plot!(framestyle=:box)
	plot!(grid=false)
end

# ╔═╡ dad4f0d3-383d-431a-bb10-1431d509673e
# savefig(pScatterGroupedSimFail, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/cr2208_allData_colored_final_hires.png")

# ╔═╡ efa7fee0-55fa-472a-9bc3-f594c5dd924d
md"""
Now finally the revised bootstrapping plots. Do we wish to show something more meaningful over here in place of 2 standard deviations??
"""

# ╔═╡ 452d0535-56ba-4023-963d-1f1aaf186285
md"""
First call the function to bootstrap GSA, we will go from 20 to 160 samples? We will not regularize since deciding how much to regularize is not a trivial question and we want a quick analysis of general trend wrt sample size.
"""

# ╔═╡ 2858cd5e-3ad1-4b92-b38d-272e3f89ec55
# begin
	# UrBootstrapFinal = bootstrapGSA(XTrainFinal, YTrainUr; regularize=false, nStart=20, nEnd=160, nStep=20)
# 	NpBootstrapFinal = bootstrapGSA(XTrainFinal, YTrainNp; regularize=false, nStart=20, nEnd=160, nStep=20)
# end

# ╔═╡ 84dbfab3-32af-4255-b2e9-b78f2f91fdab
# NpBootstrapFinal = bootstrapGSA(XTrainFinal, YTrainNp; regularize=false, nStart=20, nEnd=160, nStep=20)

# ╔═╡ ad6f09d8-0c8f-46c2-aca7-c9ba192e36b6
	# UrBootstrapFinal = bootstrapGSA(XTrainFinal, YTrainUr; regularize=false, nStart=20, nEnd=160, nStep=20)


# ╔═╡ 4e728986-4425-49cb-834c-7b4b37c2d7bc
	# save("/Users/ajivani/Desktop/Research/SWQUPaper/Ur2208BootstrapNewDataFinal.jld", "UrBootstrap", UrBootstrapFinal)


# ╔═╡ fd3f7b7e-c6e1-4e3e-9733-a8ade2fd89da
# save("/Users/ajivani/Desktop/Research/SWQUPaper/Np2208BootstrapNewDataFinal.jld", "NpBootstrap", NpBootstrapFinal)

# ╔═╡ 2b59ca2c-72b1-4365-b4bc-8bc6fff3877a
md"""
Save bootstrap data to JLD files
"""

# ╔═╡ 1f25d5eb-a1bf-4981-ba72-6925de36151c
# begin
# 	save("/Users/ajivani/Desktop/Research/SWQUPaper/Ur2208BootstrapFinal.jld", "UrBootstrap", UrBootstrapFinal)
# 	save("/Users/ajivani/Desktop/Research/SWQUPaper/Np2208BootstrapFinal.jld", "NpBootstrap", NpBootstrapFinal)
# end

# ╔═╡ 0ad392fb-2c88-424f-a0a0-fc06c16c9f06
begin
	# reload with new data
	UrBootstrapFinal = load("/Users/ajivani/Desktop/Research/SWQUPaper/Ur2208BootstrapNewDataFinal.jld", "UrBootstrap")
	# UrBootstrapFinal = load("/Users/ajivani/Desktop/Research/SWQUPaper/Ur2208BootstrapFinal.jld", "UrBootstrap")
	avgBootstrapUrFinal = mean(UrBootstrapFinal; dims=2)[:, 1, :, :]
	avgBootstrapRepsUrFinal = mean(avgBootstrapUrFinal; dims=2)[:, 1, :]
	stdBootstrapRepsUrFinal = std(avgBootstrapUrFinal; dims=2)[:, 1, :]
end

# ╔═╡ 3842c5d9-9e1b-4c92-bcb1-2e8542f43bcf
begin
	# reload with new data
	NpBootstrapFinal = load("/Users/ajivani/Desktop/Research/SWQUPaper/Np2208BootstrapNewDataFinal.jld", "NpBootstrap")
	# NpBootstrapFinal = load("/Users/ajivani/Desktop/Research/SWQUPaper/Np2152BootstrapFinal.jld", "NpBootstrap")
	avgBootstrapNpFinal = mean(NpBootstrapFinal; dims=2)[:, 1, :, :]
	avgBootstrapRepsNpFinal = mean(avgBootstrapNpFinal; dims=2)[:, 1, :]
	stdBootstrapRepsNpFinal = std(avgBootstrapNpFinal; dims=2)[:, 1, :]
end

# ╔═╡ c8c2d551-c6a0-4555-8a78-26a644c2c30a
barcolors = palette(:tab10, rev=true)

# ╔═╡ 6a4da1f2-c8a5-41b4-ada5-7547622b6269
for (sampleIdx, sampleSize) in enumerate(collect(20:20:160))
	pBarSummaryFinal = bar(
		reshape(inputNames, 1, 6),
		avgBootstrapRepsNpFinal[:, sampleIdx]',
		yerr=2 * stdBootstrapRepsNpFinal[:, sampleIdx]',
		xrot=20,
		ylims=(0, 1),
		bar_width=0.8,
		label="",
		ylabel="Main effects",
		title="N = $(sampleSize)",
		framestyle=:box,
		dpi=300,
		color=[barcolors[i] for i in 6:-1:1]',
		linewidth=2,
		markerstrokewidth=2,
		grid=false
	)
	savefig(pBarSummaryFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/bootstrapNew/cr2208_new/Np_$(sampleSize).png")
end

# ╔═╡ 83371c50-62da-46f3-84b7-2b76471faab1
md"""
Repeat process for Ur
"""

# ╔═╡ 08bb567c-7e53-46f3-b4da-cff49099d0dd
for (sampleIdx, sampleSize) in enumerate(collect(20:20:160))
	pBarSummaryFinal = bar(
		reshape(inputNames, 1, 6),
		avgBootstrapRepsUrFinal[:, sampleIdx]',
		yerr=2 * stdBootstrapRepsUrFinal[:, sampleIdx]',
		xrot=20,
		ylims=(0, 1),
		bar_width=0.8,
		label="",
		ylabel="Main effects",
		title="N = $(sampleSize)",
		framestyle=:box,
		dpi=300,
		color=[barcolors[i] for i in 6:-1:1]',
		linewidth=2,
		markerstrokewidth=2,
		grid=false
	)
	# savefig(pBarSummaryFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/bootstrapNew/cr2208/Ur_$(sampleSize).png")
	savefig(pBarSummaryFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/bootstrapNew/cr2208_new/Ur_$(sampleSize).png")
end

# ╔═╡ 54736305-fdc0-4e63-8872-2c7ce5fcd369
successBothCriteria

# ╔═╡ 1bf1c95b-c72a-417b-8d1e-053108fc2c9b
md"""
SIMIDToPlot = $(@bind EnsemblePlotID MultiSelect([string.(successBothCriteria[i]) => successBothCriteria[i] for i in 1:length(successBothCriteria)]))
"""

# ╔═╡ bdc0db73-b88b-40ad-b310-5389573fe77f
# EnsemblePlotID = deepcopy(successBothCriteria)

# ╔═╡ 100699a0-b09a-4790-9c7c-3ff2d831908b
md"""
### Scatterplots of param space
"""

# ╔═╡ 5f0ee59f-458e-48d5-bcd4-591f735e2596
successful = X_design[successfulRuns, :]

# ╔═╡ eb54ac0e-4135-4cdb-b0fe-0aff5dedbe79
failed = X_design[Not(successfulRuns), :]

# ╔═╡ 1fa64af2-1965-4748-8c79-78b62acf8060
removed = X_design[Not(runsToKeep), :]

# ╔═╡ a067b798-795c-4a57-9079-f64cdc50d35d
NamesToPlot = names(X_design)[1:6]

# ╔═╡ be6c5a27-755d-429e-8e1d-97c49ecb53c5
begin
	pParams = []
	for (i, name_x) in enumerate(NamesToPlot[1:(end - 2)])
		for (j, name_y) in enumerate(NamesToPlot[(i + 1):(end - 1)])
			pScatter = scatter(successful[!, name_x], successful[!, name_y], 
				# zcolor=shiftWLRMSE.PTRMSE, 
				marker=(:green, :circle, 4), 
				xlabel=name_x, 
				ylabel=name_y,
				markerstrokewidth=0,
				label="S"
			)

			scatter!(removed[!, name_x], removed[!, name_y],
			         marker=(:blue, :circle, :4),
					xlabel=name_x,
					ylabel=name_y,
					markerstrokewidth=0,
					label="R")
			scatter!(failed[!, name_x], failed[!, name_y],
					marker=(:red, :circle, 4),
					xlabel=name_x,
					ylabel=name_y,
					markerstrokewidth=0,
					label="F")
			push!(pParams, pScatter)
		end
	end

	plot(pParams..., layout=(2, 5), size=(1400, 800))
end

# ╔═╡ 9c623025-4b7c-4c64-b9a4-b1d8e7bb0e2f
begin
	pParamsRemaining = []
	for (i, name_x) in enumerate(NamesToPlot[1:(end-1)])
			name_y = NamesToPlot[end]
			pScatterRemaining = scatter(successful[!, name_x], successful[!, name_y], 
				# zcolor=shiftWLRMSE.PTRMSE, 
				marker=(:green, :circle, 4), 
				xlabel=name_x, 
				ylabel=name_y,
				markerstrokewidth=0,
				label="S"
			)
			scatter!(removed[!, name_x], removed[!, name_y],
			         marker=(:blue, :circle, :4),
					xlabel=name_x,
					ylabel=name_y,
					markerstrokewidth=0,
					label="R")
			scatter!(failed[!, name_x], failed[!, name_y],
					marker=(:red, :circle, 4),
					xlabel=name_x,
					ylabel=name_y,
					markerstrokewidth=0,
					label="F")
			push!(pParamsRemaining, pScatterRemaining)
	end

	plot(pParamsRemaining..., layout=(1, 5), size=(1400, 800))
end

# ╔═╡ 7448d912-79f8-41e9-ad93-e1e9b6d731b4
begin
	yvar = "PoyntingFluxPerBSi"
	xvar = "FactorB0"
	pScatterFP = scatter(successful[!, xvar], successful[!, yvar], 
	# zcolor=shiftWLRMSE.PTRMSE, 
	marker=(:green, :circle, 4), 
	xlabel=xvar, 
	ylabel=yvar,
	markerstrokewidth=0,
	label="S"
)

scatter!(removed[!, xvar], removed[!, yvar],
		 marker=(:blue, :circle, :4),
		# xlabel=name_x,
		# ylabel=name_y,
		markerstrokewidth=0,
		label="R")
scatter!(failed[!, xvar], failed[!, yvar],
		marker=(:red, :circle, 4),
		# xlabel=name_x,
		# ylabel=name_y,
		markerstrokewidth=0,
		label="F")
# plot!(sort(X_design.FactorB0), 9e5 ./ (sort(X_design.FactorB0)), line=(:pink, 2), label="9e5 (original cutoff for new design)")


end

# ╔═╡ e86fee65-a9ad-42b1-819c-1a965d4d3d8a
begin
	pScatterFPModified = scatter(successful[!, "FactorB0"], successful[!, "PoyntingFluxPerBSi"], 
	# zcolor=shiftWLRMSE.PTRMSE, 
	marker=(:green, :circle, 4), 
	xlabel="FactorB0", 
	ylabel="PoyntingFluxPerBSi",
	markerstrokewidth=0,
	label="Successful",
	dpi=350
)

scatter!(X_design[totalExcluded, "FactorB0"], X_design[totalExcluded, "PoyntingFluxPerBSi"],
		 marker=(:blue, :circle, :4),
		# xlabel=name_x,
		# ylabel=name_y,
		markerstrokewidth=0,
		label="Removed")
scatter!(failed[!, "FactorB0"], failed[!, "PoyntingFluxPerBSi"],
		marker=(:red, :circle, 4),
		# xlabel=name_x,
		# ylabel=name_y,
		markerstrokewidth=0,
		label="Failed")
plot!(sort(X_design.FactorB0), 1.2e6 ./ (sort(X_design.FactorB0)), line=(:red, 2), label="FactorB0 x PoyntingFlux = 1.2e6")

plot!(ylims=(0.3e6, 1.1e6))
# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/scatterPlotCR2208New.png")
end

# ╔═╡ 4b59c851-3c19-481d-9919-3c18d8d2ace4


# ╔═╡ fa04601d-bd70-4824-8342-87ee850a63d5
begin
	plotArgsUr = Dict(:palette=>:seaborn_bright,
				   :dateFormat=>"dd-mm HH:MM",
				   :tickInterval=>108,
				   # :simIdx => parse.(Int, EachSimID),
				   :simAlpha=>0.6, 
				   :simWidth=>1.2,
				   :ylabel=>"Uᵣ[km/s]",
				   :title=>"",
				   :startTime=>actualStartTime,
				   :dpi=>200,
				   :plotLabels=>:false,
				   
                  )

	plotArgsNp = Dict(:palette=>:seaborn_bright,
					   :dateFormat=>"dd-mm HH:MM",
					   :tickInterval=>108,
					   # :simIdx => parse.(Int, EachSimID),
					   :simAlpha=>0.6, 
					   :simWidth=>1.2,
					   :ylabel=>"Nₚ[cm⁻³]",
					   # :ylabel=>"Np [cm" * L"^{-3}" * "]",
					   :title=>"",
					   :startTime=>actualStartTime,
					   :dpi=>200,
					   :ylims=>(0, 80),
					   :plotLabels=>:false
					  )

	plotArgsB = Dict(:palette=>:seaborn_bright,
					   :dateFormat=>"dd-mm HH:MM",
					   :tickInterval=>108,
					   # :simIdx => parse.(Int, EachSimID),
					   :simAlpha=>0.6, 
					   :simWidth=>1.2,
					   :ylabel=>"B[nT]",
					   # :ylabel=>"Np [cm" * L"^{-3}" * "]",
					   :title=>"",
					   :startTime=>actualStartTime,
					   :dpi=>200,
					   :ylims=>(0, 20),
					   :plotLabels=>:false,
					   :subtractFactor=>0
	                  )

	plotArgsT = Dict(:palette=>:seaborn_bright,
				   :dateFormat=>"dd-mm HH:MM",
				   :tickInterval=>108,
				   # :simIdx => parse.(Int, EachSimID),
				   :simAlpha=>0.6, 
				   :simWidth=>1.5,
				   :ylabel=>"T[K]",
				   # :ylabel=>"Np [cm" * L"^{-3}" * "]",
				   :title=>"",
				   :startTime=>actualStartTime,
				   :dpi=>200,
				   :ylims=>(0, 9e5),
				   :plotLabels=>:false,
				   :subtractFactor=>0
				  )
end

# ╔═╡ 47ad7549-e711-42a4-a29b-493515363355
begin
	pUr = plotExcludedSimObs(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, ExcludedSims), plotArgsUr..., ylims=(0, 1100))
	pNp = plotExcludedSimObs(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, ExcludedSims), plotArgsNp..., ylims=(0, 120))
	pB  = plotExcludedSimObs(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, ExcludedSims), plotArgsB..., ylims=(0, 30))
	plot(pUr, pNp, pB, layout=(1, 3), xlabel="", size=(1500, 800))
	plot!(xrot=10)
	plot!(title="Runs Discarded")
	# plot!(xrot=25)
end

# ╔═╡ b33ccfaf-31b4-4264-ab0f-99c0002610a5
begin
	pUrS = plotSimObs(UrSim, UrObs, times, collect(1:200); simIdx=runsToKeep, plotArgsUr..., ylims=(0, 1100))
	pNpS = plotSimObs(NpSim, NpObs, times, collect(1:200); simIdx=runsToKeep, plotArgsNp..., ylims=(0, 120))
	pBS = plotSimObs(BSim, BObs, times, collect(1:200); simIdx=runsToKeep, plotArgsB...)
	plot(pUrS, pNpS, pBS, layout=(1, 3), xlabel="", size=(1500, 800))
	plot!(xrot=10)
	plot!(title="Runs Used")
	
	# plot!(xrot=25)
end

# ╔═╡ 8e96c014-f34b-48d2-8c85-a40610a8725b
begin
	pUrSModified = plotSimObs(UrSim, UrObs, times, collect(1:200); simIdx=setdiff(1:200, totalExcluded), plotArgsUr..., dpi=300, ylims=(180, 800))
	# savefig("/Users/ajivani/Downloads/UrSims.png")
end

# ╔═╡ a17c9fc2-63f1-4707-bdb9-0aa8da50a609
# begin
# 	plotArgsUr = Dict(:palette=>:seaborn_bright,
# 				   :dateFormat=>"dd-mm HH:MM",
# 				   :tickInterval=>108,
# 				   # :simIdx => parse.(Int, EachSimID),
# 				   :simAlpha=>0.75, 
# 				   :simWidth=>2.0,
# 				   :ylabel=>"Ur [km/s]",
# 				   :title=>"",
# 				   :startTime=>actualStartTime,
# 				   :dpi=>350,
# 				   :plotLabels=>:false,
# 				   :subtractFactor=>0,
#                   )

# 	plotArgsNp = Dict(:palette=>:seaborn_bright,
# 					   :dateFormat=>"dd-mm HH:MM",
# 					   :tickInterval=>108,
# 					   # :simIdx => parse.(Int, EachSimID),
# 					   :simAlpha=>0.75, 
# 					   :simWidth=>2.0,
# 					   :ylabel=>"Np[cm⁻³]",
# 					   # :ylabel=>"Np [cm" * L"^{-3}" * "]",
# 					   :title=>"",
# 					   :startTime=>actualStartTime,
# 					   :dpi=>350,
# 					   :ylims=>(0, 80),
# 					   :plotLabels=>:false,
# 					   :subtractFactor=>0
# 					  )

# 	plotArgsB = Dict(:palette=>:seaborn_bright,
# 					   :dateFormat=>"dd-mm HH:MM",
# 					   :tickInterval=>108,
# 					   # :simIdx => parse.(Int, EachSimID),
# 					   :simAlpha=>0.75, 
# 					   :simWidth=>2.0,
# 					   :ylabel=>"B[nT]",
# 					   # :ylabel=>"Np [cm" * L"^{-3}" * "]",
# 					   :title=>"",
# 					   :startTime=>actualStartTime,
# 					   :dpi=>350,
# 					   :ylims=>(0, 20),
# 					   :plotLabels=>:false,
# 					   :subtractFactor=>0
# 	                  )

# 	plotArgsT = Dict(:palette=>:seaborn_bright,
# 				   :dateFormat=>"dd-mm HH:MM",
# 				   :tickInterval=>108,
# 				   # :simIdx => parse.(Int, EachSimID),
# 				   :simAlpha=>0.75, 
# 				   :simWidth=>2.0,
# 				   :ylabel=>"T [K]",
# 				   # :ylabel=>"Np [cm" * L"^{-3}" * "]",
# 				   :title=>"",
# 				   :startTime=>actualStartTime,
# 				   :dpi=>350,
# 				   :ylims=>(0, 9e5),
# 				   :plotLabels=>:false,
# 				   :subtractFactor=>0
# 				  )
# end

# ╔═╡ e7e9d13b-8d82-4fca-b2fd-9b839207081e
md"""
### Bootstrapping analysis

Let's draw sample sizes starting from 20, incrementing by 20 and going to 160. We will plot the summary plots that show the variability of the Sobol indices.

"""

# ╔═╡ a9bf4f3d-25b2-4016-bfc8-ef8500bcd3e1
# UrBootstrap = bootstrapGSA(X, Y1; regularize=false, nStart=20, nEnd=140, nStep=20)

# ╔═╡ 2fa3add3-7247-4d5b-a08d-a4d2cec794f2
# NpBootstrap = bootstrapGSA(X, Y2; regularize=false, nStart=20, nEnd=140, nStep=20)

# ╔═╡ 4f35dc1d-0178-4456-adb7-c4fdfd5abe08
# size(NpBootstrap)

# ╔═╡ fca97d6c-9baf-49ba-b346-28b9137c4471
begin
	UrBootstrap = load("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapUr2208.jld", "UrBootstrap")
	avgBootstrapUr = mean(UrBootstrap; dims=2)[:, 1, :, :]
	avgBootstrapRepsUr = mean(avgBootstrapUr; dims=2)[:, 1, :]
	stdBootstrapRepsUr = std(avgBootstrapUr; dims=2)[:, 1, :]
end

# ╔═╡ 51043712-df90-4058-858f-b00fdb42177e
NpBootstrap = load("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapNp2208.jld", "NpBootstrap")

# ╔═╡ ef261d67-219d-4004-8371-3c0dee1fe4b3
# plotBootstrapSummary(NpBootstrap; inputNames, nReplications=1000, samplingRange=20:20:140, saveDir="/Users/ajivani/Desktop/Research/SWQUPaper/1000Reps/", dRep=25)

# ╔═╡ 69e46514-8bc7-4122-ad05-e3e95aa9a621
stdBootstrapRepsUr

# ╔═╡ c5a99a95-a4fd-40ff-a1a4-e0fed2dfb280
begin

	# plot average of bootstrap results across replications and across time
	avgBootstrapNp = mean(NpBootstrap; dims=2)[:, 1, :, :]
	# stdBootstrapNp = std(NpBootstrap; dims=2)[:, 1, :, :]
	avgBootstrapRepsNp = mean(avgBootstrapNp; dims=2)[:, 1, :]
	stdBootstrapRepsNp = std(avgBootstrapNp; dims=2)[:, 1, :]
end

# ╔═╡ ac31e8ae-a691-427d-83c2-82cefecf76e1
stdBootstrapRepsNp

# ╔═╡ 2aa6658f-73b8-4fa1-98e1-dcda14b483ac
linecolors = palette(:default)

# ╔═╡ 21125794-7268-4388-8e34-71227ac65f1b
for (sampleIdx, sampleSize) in enumerate(collect(20:20:140))
	pBarSummary = bar(inputNames,
		avgBootstrapRepsUr[:, sampleIdx],
		yerr=stdBootstrapRepsUr[:, sampleIdx],
		xrot=20,
		ylims=(0, 1),
		bar_width=1.0,
		label="",
		ylabel="Main effects",
		title="N = $(sampleSize)",
		framestyle=:box,
		dpi=400,
		fillcolor=linecolors[1],
		linewidth=2,
		markerstrokewidth=2,
		grid=false
	)
	# savefig(pBarSummary, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/bootstrap/cr2208/Ur_$(sampleSize).png")
end

# ╔═╡ c195d569-7274-45db-bc0d-817e4fc98bc4
begin
	# replace bar charts by line plots and use to summarize effect of increasing N (combine multiple bar charts into a single plot!!!)
	summaryColors = barcolors[6:-1:1]
	pLineSummaryUr = plot()
	for (idx, eachName) in enumerate(inputNames)
		meanTrend = avgBootstrapRepsUr[idx, :]
		errTrend  = stdBootstrapRepsUr[idx, :] 
		plot!(20:20:140, meanTrend, 
			yerr=errTrend,
			linewidth=2.5,
			linecolor=summaryColors[idx], 
			marker=:circle,
			markersize=6,
			markercolor=summaryColors[idx],
			markerstrokecolor=summaryColors[idx],
			markerstrokewidth=1.5,
			label=eachName)
	end
	plot!(legend=:outertopright)
	plot!(xticks=(20:20:140, string.(20:20:140)))
	plot!(xlabel="Sample size N")
	plot!(ylabel="Main Effects")
	plot!(guidefontsize=20)
	plot!(tickfontsize=16)
	plot!(leftmargin=5mm)
	plot!(bottommargin=5mm)
	plot!(framestyle=:box)
	plot!(size=(850, 500))
	plot!(ylims=(0, 0.5))
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/bootstrap_cr2208_final_line_Ur.png")
end

# ╔═╡ 88c6340b-183b-4bc0-a71a-aa97125f1cd9
begin
	# replace bar charts by line plots and use to summarize effect of increasing N (combine multiple bar charts into a single plot!!!)
	pLineSummaryNp = plot()
	for (idx, eachName) in enumerate(inputNames)
		meanTrend = avgBootstrapRepsNp[idx, :]
		errTrend  = stdBootstrapRepsNp[idx, :] 
		plot!(20:20:140, meanTrend, 
			yerr=errTrend,
			linewidth=2.5,
			linecolor=summaryColors[idx], 
			marker=:circle, 
			markercolor=summaryColors[idx],
			markerstrokecolor=summaryColors[idx],
			markerstrokewidth=1.5,
			label=eachName)
	end
	plot!(legend=:outertopright)
	plot!(xticks=(20:20:140, string.(20:20:140)))
	plot!(xlabel="Sample size N")
	plot!(ylabel="Main Effects")
	plot!(guidefontsize=20)
	plot!(tickfontsize=16)
	plot!(leftmargin=5mm)
	plot!(bottommargin=5mm)
	plot!(framestyle=:box)
	plot!(size=(850, 500))
	plot!(ylims=(0, 0.5))
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/bootstrap_cr2208_final_line_Np.png")
end

# ╔═╡ 8f201720-902f-44ee-8ef8-a896730200b3


# ╔═╡ 1b29310c-8b2d-4bba-843f-f5790447707d


# ╔═╡ 086cf67b-009d-49f5-80b7-e8b9bd91337a


# ╔═╡ 58cf45d9-4e3e-4056-84ad-06a3efb682ca
begin
	ott = range(times[1], times[end], step=Hour(72))
	Dates.format.(ott, "dd-u")
end

# ╔═╡ 47eae398-661b-4a35-be30-16547c71fe7b
function plotMainEffects2(mainEffects, timeData, inputNames;
						  palette=palette(:tab10, rev=true),
						  tickStep=72,
						  tickFormat="dd-mm",
						  title="Sensitivity for Ur",
						  ylabel="Main effects",
						  lineWidth=0.0,
					      barWidth=2,
						  dpi=400,
						  showLabels=true
						)

	mainEffectsReversed = reverse(mainEffects', dims=2)
	obsTimeTicks = range(timeData[1], timeData[end], step=Hour(tickStep))
    xticks  = findall(in(obsTimeTicks), timeData)
    xticklabels = Dates.format.(obsTimeTicks, tickFormat)

	if showLabels
		label=permutedims(reverse(inputNames))
	else
		label=""
	end
	groupedbar(
		mainEffectsReversed,
		bar_position=:stack,
		bar_width=barWidth,
		legend=:outertopright,
		label=label,
		xticks=(xticks, xticklabels),
		xminorticks=12,
		figsize=(1000, 600),
		color=[palette[i] for i in 1:size(mainEffectsReversed, 2)]',
		line=(lineWidth, :black),
		title=title,
		xlims=(1, length(timeData)),
		ylims=(0, 1),
		dpi=dpi,
		framestyle=:box,
		)
	plot!(xlabel = "Start Time: $(Dates.format(DateTime(actualStartTime, "yyyy_mm_ddTHH:MM:SS"), "dd-u-yy HH:MM:SS"))")
	# plot!(xlabel = "Start Time: $(actualStartTime)")
    plot!(ylabel = ylabel)
end

# ╔═╡ 91d7393d-f8fb-49a1-ade0-6a4d3650ff00
begin
	pMainUr = plotMainEffects2(mainEffectsUr, times, inputNames)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/ME2208Ur.png")
end

# ╔═╡ 12df4a54-1450-4bff-9509-298aa1604664
begin
	pMainNp = plotMainEffects2(mainEffectsNp, times, inputNames, ylabel="Nₚ")
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/ME2152Np.png")
end

# ╔═╡ d196ab6f-5c67-4efb-a44d-02fb80fcd970
begin
	pUrMain = plotMainEffects2(mainEffectsUr, times, inputNames, ylabel="Ur", showLabels=true)
	plot!(parse(Int, timeIdx) * ones(50), range(0, 1, length=50), line=(:red, 2), label="")
	pNpMain = plotMainEffects2(mainEffectsNp, times, inputNames, ylabel="Np")
	plot!(parse(Int, timeIdx) * ones(50), range(0, 1, length=50), line=(:red, 2), label="")
	plot(pUrMain, pNpMain, layout=(1, 2), size=(1400, 600))
end

# ╔═╡ b06ad072-bafb-4dea-bb36-4438e7b449a8
begin
	pMainUrFinal = plotMainEffects2(gsaMainUrFinal, times, inputNames; title="Sensitivity for Uᵣ", dpi=300)
	plot!(grid=false)
	plot!(xtickfontsize=8)
	plot!(ytickfontsize=10)
	plot!(guidefontsize=13)
end

# ╔═╡ 3946e40f-0653-4df7-b646-13c28f96ce0b
savefig(pMainUrFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2208_allData_ur_me_final.png")

# ╔═╡ 6b6dc645-c6f9-42eb-9eda-9f7dacc04fba
begin
	pMainNpFinal = plotMainEffects2(gsaMainNpFinal, times, inputNames; title="Sensitivity for Nₚ", dpi=300)
	plot!(xtickfontsize=8)
	plot!(ytickfontsize=10)
	plot!(guidefontsize=13)
	plot!(grid=false)
end

# ╔═╡ 8f0605a2-3fc9-41d1-a68e-c8619c0b43f8
savefig(pMainNpFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2208_allData_np_me_final.png")

# ╔═╡ b7085722-7a6e-4c74-980c-8f382dd20624
Dates.format(DateTime(actualStartTime, "yyyy_mm_ddTHH:MM:SS"), "dd-u-yy HH:MM:SS")

# ╔═╡ d3cbdc82-7f95-4857-8cb0-55e6f294192e


# ╔═╡ 00e4b8d6-4c25-44f5-8f22-e448e861989e

"""
Replicate Python function. Plot ONLY one half of the Matrix
and include text labels to annotate.
"""
function plotInteractionEffects2(gsaIndices, 
                            timeData,
                            inputNames;
                            trimIndices=(1, 720), 
                            timeIdx=nothing,
                            dpi=300,
                            color=:viridis,
						    clims=(0, 0.5)
                            # summaryPlot="mean"
                            )
    if !isnothing(timeIdx)
        interactions = LowerTriangular(gsaIndices[:, :, timeIdx])
        # _, obsTimes = processTimeInfo(timeData; trimIndices=trimIndices)
        plotTime = timeData[timeIdx]
        plotTitle = "Time:  $(Dates.format(plotTime, "dd-u-yy HH:MM:SS"))"
    else
        # interactions = LowerTriangular(mean(gsaIndices, dims=3)[:, :, 1])
        interactions = mean(gsaIndices, dims=3)[:, :, 1]
        plotTitle = "Mean Interaction Effects"
    end

    nrow, ncol = size(interactions)
    # interactions2 = deepcopy(interactions)
    # for i in 1:nrow
    #     for j in (i + 1):(ncol - 1)
    #         interactions2[i, j] = NaN
    #     end
    # end
    
    # interactions[maskElements] .= NaN

    # Tick labels
    # xTickLabels = permutedims(reverse(inputNames))
    xlabels = inputNames
    # Plot heatmap with annotations
    interactionPlot = Plots.heatmap(
                            #   inputNames,
                            #   inputNames,
                              interactions,
                              yflip=true,
                              c=color,
                              xrot=20,
                              xticks=(1:6, xlabels),
                              yticks=(1:6, xlabels),
                              fillalpha=0.7,
                              grid=false,
                              framestyle=:box,
                              dpi=dpi,
							  clims=clims
                            )

    thresh = maximum(interactions) / 2
    fontsize=10
    ann_thresh = [interactions[j, i] >= thresh ? (i,j, text(round(interactions[j, i], digits=2), fontsize, :black, :center)) : (i, j, text(round(interactions[j, i], digits=2), fontsize, :white, :center))
                           for i in 1:nrow for j in 1:ncol]
    

    annotate!(ann_thresh, linecolor=:white)
	plot!(title=plotTitle)
    # # 
    # return interactionPlot
    return interactionPlot
end

# ╔═╡ a4439729-6e8e-4910-aed2-e893319b8b27
begin
	pUrInt = plotInteractionEffects2(gsaIndicesUr, times, inputNames; timeIdx=parse(Int, timeIdx))
	pNpInt = plotInteractionEffects2(gsaIndicesNp, times, inputNames; timeIdx=parse(Int, timeIdx))
	plot(pUrInt, pNpInt, layout=(1, 2), size=(1400, 600))
end

# ╔═╡ 68854811-b485-4222-ad9d-1a250199cc9d
begin
	pUrIntMean = plotInteractionEffects2(gsaIndicesUr, times, inputNames)
	pNpIntMean = plotInteractionEffects2(gsaIndicesNp, times, inputNames)
	plot(pUrIntMean, pNpIntMean, layout=(1, 2), size=(1400, 600))
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/IE2152.png")
end

# ╔═╡ 35a5c725-b392-4bf3-b6a0-bf81fa4883b4
pUrIntMean

# ╔═╡ dfe95808-a81e-48e0-8dc2-f831ef73c2bc
savefig(pUrIntMean, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/new/IE2208Ur.png")

# ╔═╡ 5c8d88ee-d326-49db-a630-43699ad8cd0b
begin
	plotInteractionEffects2(gsaUrFinal, times, inputNames, dpi=300)
	plot!(tickfontsize=10)
end

# ╔═╡ 9fac1906-f4ff-4d5e-afe2-e81caed07e97
begin
	pUrIntMeanFinal = plotInteractionEffects2(gsaUrFinal, times, inputNames, dpi=300)
	plot!(tickfontsize=12)
	plot!(bottom_margin=9mm)
	plot!(right_margin=3mm)
	pNpIntMeanFinal = plotInteractionEffects2(gsaNpFinal, times, inputNames, dpi=300)
	plot!(tickfontsize=12)
	plot!(bottom_margin=9mm)
	plot!(right_margin=3mm)
	plot(pUrIntMeanFinal, pNpIntMeanFinal, layout=(1, 2), size=(1400, 600))
	# savefig("/Users/ajivani/Downloads/IE2152.png")
end

# ╔═╡ 6034bdfe-d518-4880-b281-698f4b614bda
"""
Replicate Python function. Plot ONLY one half of the Matrix
and include text labels to annotate.
"""
function plotInteractionSummary(interaction1,
							interaction2,
                            timeData,
                            inputNames;
                            trimIndices=(1, 720), 
                            timeIdx=nothing,
                            dpi=500,
                            color=:viridis,
						    clims=(0, 0.5)
                            # summaryPlot="mean"
                            )
    # if !isnothing(timeIdx)
    #     interactions = LowerTriangular(gsaIndices[:, :, timeIdx])
    #     # _, obsTimes = processTimeInfo(timeData; trimIndices=trimIndices)
    #     plotTime = timeData[timeIdx]
    #     plotTitle = "Time:  $(Dates.format(plotTime, "dd-u-yy HH:MM:SS"))"
    # else
    #     # interactions = LowerTriangular(mean(gsaIndices, dims=3)[:, :, 1])
    #     interactions = mean(gsaIndices, dims=3)[:, :, 1]
    #     plotTitle = "Mean Interaction Effects"
    # end
	plotTitle = "Mean Interaction Effects"
	interactions = 0.5 * (interaction1 + interaction2)

    nrow, ncol = size(interactions)
    # interactions2 = deepcopy(interactions)
    # for i in 1:nrow
    #     for j in (i + 1):(ncol - 1)
    #         interactions2[i, j] = NaN
    #     end
    # end
    
    # interactions[maskElements] .= NaN

    # Tick labels
    # xTickLabels = permutedims(reverse(inputNames))
    xlabels = inputNames
    # Plot heatmap with annotations
    interactionPlot = Plots.heatmap(
                            #   inputNames,
                            #   inputNames,
                              interactions,
                              yflip=true,
                              c=color,
                              xrot=20,
                              xticks=(1:6, xlabels),
                              yticks=(1:6, xlabels),
                              fillalpha=0.7,
                              grid=false,
                              framestyle=:box,
                              dpi=dpi,
							  clims=clims
                            )

    thresh = maximum(interactions) / 2
    fontsize=10
    ann_thresh = [interactions[j, i] >= thresh ? (i,j, text(round(interactions[j, i], digits=2), fontsize, :black, :center)) : (i, j, text(round(interactions[j, i], digits=2), fontsize, :white, :center))
                           for i in 1:nrow for j in 1:ncol]
    

    annotate!(ann_thresh, linecolor=:white)
	plot!(title=plotTitle)
    # # 
    # return interactionPlot
    return interactionPlot
end

# ╔═╡ 04e00e04-3d3a-4a58-a0cb-aeec26a10e85
begin
	pIntMeanAll = plotInteractionSummary(interactionsUr, interactionsNp, times, inputNames)
	# savefig("/Users/ajivani/Downloads/pIntMeanCR2208.png")
end

# ╔═╡ f25d730c-639b-4ff0-9856-f0e14dbff23c
"""
For L1, plot simulations and observations of different QoIs. Modified from the original plotUtils functions to be more suitable for this analysis.
"""
function plotSimObs2(sim, obs, times, runs; 
                simIdx = 1:10,
                highlightIdx=1,
                palette=:Dark2_8,
                ylabel="QoI",
                ylims=(200, 900),
                tickInterval=12,
                title="Ur",
                plotLabels=false,
                legend=true,
                simAlpha=0.8,
                simWidth=1.5,
                dateFormat="dd-m HH:MM",
                dpi=500,
                subtractFactor=20,
                startTime="2015-03015T03:15:00"
                )
    if simIdx[1] isa String
        simIdx = parse.(Int, simIdx)
    end
    # colIdx = findall(in(simIdx .- subtractFactor), runsToKeep)
    nLines = length(simIdx)
    if plotLabels
        labelsVec = "run " .* string.(simIdx)
        lineLabels = reshape(labelsVec, 1, nLines)
        obsLabel = "OMNI"
    else
        lineLabels = ""
        obsLabel = ""
    end
    p = plot(1:length(times), sim[:, simIdx], 
    line=(simWidth), 
    line_z=(1:length(simIdx))',
    linealpha=simAlpha, 
    color=palette,
    label=lineLabels,
    dpi=dpi,
    )

    # plot!(1:length(times), obs, 
    # line=(:black, 2.5), 
    # label=obsLabel,
    # #minorgrid=true,
    # yminorticks=10
    # )

    obsTimeTicks = range(times[1], times[end], step=Hour(tickInterval))
    xticks  = findall(in(obsTimeTicks), times)
    xticklabels = Dates.format.(obsTimeTicks, dateFormat)

    # startTimeFormatted = Dates.format(Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS") - Minute(30),
                        # "dd-u-yy HH:MM:SS") 
    startTimeFormatted = Dates.format(Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS"),
                        "dd-u-yy HH:MM:SS") 
    plot!(xlabel="Start Time: " * startTimeFormatted)
    plot!(ylabel=ylabel)
    plot!(xticks=(xticks, xticklabels))
    plot!(xminorticks=8),
    plot!(xlims=(1, length(times)))
    plot!(ylims=ylims)
    plot!(framestyle=:box)
    plot!(grid=false)
    plot!(legend=:outertopright),
    plot!(fg_legend=:false),
    plot!(colorbar=false)
    plot!(title=title)
    return p
end

# ╔═╡ bf379789-7caa-4231-b5c2-b1f536e733ab
begin
	pUrSimObs = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsUr...)
	pNpSimObs = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsNp...)
	pBSimObs  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsB...)
	plot(pUrSimObs, pNpSimObs, pBSimObs, layout=(1, 3), xlabel="", size=(1500, 800))
	plot!(xrot=10)
	plot!(title="All Successful")
	# plot!(xrot=25)
end

# ╔═╡ f2edb22d-acfa-411d-8259-21cf13f4ce4f
pUrSimObs

# ╔═╡ 7e2e7dab-1bf3-4f4c-9519-f51887c49bad
# make plots of only runs that are successful and satisfy the constraints
begin
	pUrSimObs2 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsUr...)
	pNpSimObs2 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsNp..., ylims=(0, 100))
	pBSimObs2  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsB...)
	plot(pUrSimObs2, pNpSimObs2, pBSimObs2, layout=(1, 3), xlabel="", size=(1500, 800))
	plot!(xrot=10)
	plot!(title="All Successful")
	# plot!(xrot=25)
end

# ╔═╡ 899202da-133f-45cb-864d-e1292cba7df1
begin
pBSimObs2
pBSimObs2L = plot(pBSimObs2)
end

# ╔═╡ 5a37d7f2-1551-40f5-aed0-a909c3ddd52d
pUrSimObs2

# ╔═╡ 2c06d124-3cca-40c7-aebb-6d7632b4c70c
begin
	pTSimObs2 = plotSimObs2(TSim, TObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsT...)
	# pTSimObs2L = plot(pTSimObs2, legend=false)
	pTSimObs2L = plot(pTSimObs2)
end

# ╔═╡ b0c0febe-0953-4697-a790-1f7a5df89811
begin
	savefig(pUrSimObs2, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/UrSims_CR2208.png")
	savefig(pNpSimObs2, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/NpSims_CR2208.png")
	savefig(pBSimObs2L, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/BSims_CR2208.png")
	savefig(pTSimObs2L, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/TSims_CR2208.png")
end

# ╔═╡ 71dcbd12-f573-4cb7-9c97-4d1fb4251ac0
begin
	pUrSimObsF = plotSimObs2(UrSimFinal, UrObsFinal, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsUr..., ylims=(100, 1000))
	plot!(guidefontsize=16)
	plot!(left_margin=5mm)
	plot!(bottom_margin=3mm)
	plot!(ytickfontsize=10)
end

# ╔═╡ d27b601e-d968-456b-b83c-9111632e4f6f
begin
	pNpSimObsF = plotSimObs2(NpSimFinal, NpObsFinal, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsNp..., ylims=(0, 100))
		plot!(guidefontsize=16)
		plot!(left_margin=5mm)
		plot!(bottom_margin=3mm)
		plot!(ytickfontsize=10)
end

# ╔═╡ 6c2a3e15-be2b-467f-80fb-b7ec89b42168
begin
	savefig(pUrSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/UrSims_CR2208_allData_final_noobs.png")
	savefig(pNpSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/NpSims_CR2208_allData_final_noobs.png")
	# savefig(pBSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/BSims_CR2208_allData_final_noobs.png")
	# savefig(pTSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/TSims_CR2208_allData_final_noobs.png")
end

# ╔═╡ 56a4e7b8-3537-4c1d-8b41-60691b549cc4
begin
pBSimObsF  = plotSimObs2(BSimFinal, BObsFinal, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsB...)
		plot!(guidefontsize=16)
		plot!(left_margin=5mm)
		plot!(bottom_margin=3mm)
		plot!(ytickfontsize=10)
end

# ╔═╡ 26451125-a996-4ea2-ba79-ef186f7a6c17
begin
	pTSimObsF = plotSimObs2(TSimFinal, TObsFinal, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsT..., ylims=(0, 10e5))
	plot!(yticks=(0:1e5:10e5, [0; [@sprintf("%de5", i) for i in 1:10]][:]))
			plot!(guidefontsize=16)
		plot!(left_margin=5mm)
		plot!(bottom_margin=3mm)
		plot!(ytickfontsize=10)
end

# ╔═╡ 616e845c-2cf7-47b5-bfa1-8a849072cf7b


# ╔═╡ e5752416-2ebc-4ebc-bc65-711792763fd9
"""
Function to plot main effect summary.
"""
function plotMainSummary(mainEffects1, mainEffects2,
                            timeData,
                            inputNames;
                            trimIndices=(1, 720), 
                            timeIdx=nothing,
                            dpi=500,
                            color=:viridis,
						    clims=(0, 0.5)
                            # summaryPlot="mean"
                            )
        # interactions = LowerTriangular(mean(gsaIndices, dims=3)[:, :, 1])
        plotTitle = "Average Main Effects"
        avgEffects1 = mean(mainEffects1, dims=2)
		avgEffects2 = mean(mainEffects2, dims=2)
		avgEffects = [avgEffects1 avgEffects2]
    nrow, ncol = size(avgEffects)
    # interactions2 = deepcopy(interactions)
    # for i in 1:nrow
    #     for j in (i + 1):(ncol - 1)
    #         interactions2[i, j] = NaN
    #     end
    # end
    
    # interactions[maskElements] .= NaN

    # Tick labels
    # xTickLabels = permutedims(reverse(inputNames))
    xlabels = ["Ur" "Np"]
	ylabels = inputNames
    # Plot heatmap with annotations
    interactionPlot = Plots.heatmap(
                            #   inputNames,
                            #   inputNames,
                              avgEffects,
                              yflip=true,
                              c=color,
                              # xrot=20,
                              xticks=(1:2, xlabels),
                              yticks=(1:6, ylabels),
                              fillalpha=0.7,
							  # linewidth=2,
							  markerstrokewidth=2,
                              grid=false,
                              framestyle=:box,
                              dpi=dpi,
							  clims=clims
                            )

    thresh = maximum(avgEffects) / 2
    fontsize=10
    ann_thresh = [avgEffects[j, i] >= thresh ? (i,j, text(round(avgEffects[j, i], digits=2), fontsize, :black, :center)) : (i, j, text(round(avgEffects[j, i], digits=2), fontsize, :white, :center))
                           for i in 1:ncol for j in 1:nrow]
    

    annotate!(ann_thresh, linecolor=:white)
	plot!(title=plotTitle)
    # # 
    # return interactionPlot
    return interactionPlot
end

# ╔═╡ b666987d-6bd3-41f4-a638-0d8ddfdda00c
begin
		ppMainAvg = plotMainSummary(mainEffectsUr, mainEffectsNp, times, inputNames)
		vline!([1.5], line=(:black, 2), label="")
		vline!([0.5], line=(:black, 3), label="")
		vline!([2.5], line=(:black, 3), label="")
		hline!([0.5], line=(:black, 3), label="")
	hline!([0.5], line=(:black, 3), label="")
	hline!([1.5], line=(:black, 2), label="")
	hline!([2.5], line=(:black, 2), label="")
	hline!([3.5], line=(:black, 2), label="")
	hline!([4.5], line=(:black, 2), label="")
	hline!([5.5], line=(:black, 2), label="")
	hline!([6.5], line=(:black, 3), label="")
	# savefig("/Users/ajivani/Downloads/solar_max_me_summary.png")
		# plot!(size=(800, 900))
		# plot!(1.5 * ones(12), 0:0.5:5.5, line=(:black, 2), label="")
end

# ╔═╡ Cell order:
# ╠═543596ec-a6e5-4779-a2a9-fea1ceb7a700
# ╠═933ae98e-d0eb-11ec-1ba6-2fc31d8c1510
# ╟─83350690-3b47-4af7-aaed-474793c23219
# ╠═dc90bbc7-c265-4850-9f13-71d9705d45be
# ╟─6765dcad-b067-47de-98f4-d1eba31be765
# ╠═5ec433c9-0f37-4584-aace-7c1bec6fbf05
# ╠═003792f0-b399-4eba-8dd2-2da32b587219
# ╠═46168df1-54af-4547-99c8-06b42a4ac864
# ╠═09e9a23f-7c39-4ce4-9f57-d1c3b71dd07c
# ╠═dfbaccaf-66af-43ea-88d8-a6e9764b146f
# ╠═18fb7539-a8aa-42b8-a78c-ece38b3b6174
# ╠═f785df1e-43df-4dcf-95d5-ce4d0565ad4a
# ╠═a20007c6-5c90-4fff-8618-9055ce884851
# ╠═5ab604d5-584c-4b25-9e31-39d6ae13749a
# ╠═3823f232-40bc-40c3-87ef-d8b6ba7ddd38
# ╟─dde2906d-a892-48eb-abdf-836d2e555d22
# ╠═13946121-5d6e-4370-97d5-888e66e4b3d9
# ╠═444f5b42-fb30-47bc-9634-a69cfe13dcb2
# ╠═e823c7bc-1b92-4397-b9fb-e29d0e8c0ac0
# ╠═332d1132-9de4-4908-8125-c0f1cb7d4277
# ╠═a7d9bc78-04bf-4404-83bc-db10c92e1cce
# ╠═5f24f3ec-d63b-4030-90d4-e967f433e54e
# ╠═c18f5f64-72b9-4384-b1e6-858cfea0dd34
# ╠═3441f2a4-c49e-4851-8409-575b7c319b5f
# ╠═5448968e-a994-497e-8428-829616a09eed
# ╠═2517208e-d33b-4114-891d-bf26fa652073
# ╠═178417f2-6130-4cc0-922c-541e1e5ecffb
# ╠═e3426359-25dd-4741-a2d3-1afbe0d77b05
# ╠═8d6a5d8c-a0e4-458c-b69c-fc1d35031497
# ╠═8f18a9c8-68f8-4e0a-9c7d-47ed909344a7
# ╠═bf379789-7caa-4231-b5c2-b1f536e733ab
# ╠═fd112ea1-af42-49be-b5e0-fb10df932403
# ╠═7e2e7dab-1bf3-4f4c-9519-f51887c49bad
# ╠═2c06d124-3cca-40c7-aebb-6d7632b4c70c
# ╠═899202da-133f-45cb-864d-e1292cba7df1
# ╠═5a37d7f2-1551-40f5-aed0-a909c3ddd52d
# ╠═b0c0febe-0953-4697-a790-1f7a5df89811
# ╠═f2edb22d-acfa-411d-8259-21cf13f4ce4f
# ╠═c3fae2e1-a911-47c6-871a-79e016e47874
# ╠═04492c0c-b5ba-4884-bb3c-9dc089484691
# ╠═5e2d1470-c487-46ed-b08d-af4a265e977d
# ╠═630fcdb2-ef98-4ae8-ad15-3ebfe37c4e00
# ╠═9d9351e0-fce0-492c-a44c-3f2100c6cd00
# ╠═d12bc2f6-2a09-4b18-90e0-317da7dec7c2
# ╠═88fd5d74-437d-4ca9-a89f-95aa1dff0164
# ╠═d6733c06-c6da-470e-bdba-6621816fc644
# ╟─47ad7549-e711-42a4-a29b-493515363355
# ╠═b33ccfaf-31b4-4264-ab0f-99c0002610a5
# ╠═8e96c014-f34b-48d2-8c85-a40610a8725b
# ╟─5bd0e50a-6cac-471d-b29c-ab966777028b
# ╠═78eeb3d4-0528-4253-802f-d164e47e759e
# ╠═ee362fc8-1c74-4561-b1d8-db94d0648e96
# ╠═bbdcc6ba-e6ae-470b-8b51-9ebbaa8b2a5f
# ╠═caa03923-fb76-4fbb-97fa-8180838df025
# ╠═16f9b679-e8c5-4425-ab3e-ef8afd36f7f5
# ╠═91d7393d-f8fb-49a1-ade0-6a4d3650ff00
# ╠═21b9bd18-4e4a-401a-b7a8-f361d73526b6
# ╠═12df4a54-1450-4bff-9509-298aa1604664
# ╟─d196ab6f-5c67-4efb-a44d-02fb80fcd970
# ╠═a0726b0a-5864-4323-869c-fb9d3b533473
# ╠═60e83fd4-6cbe-4e4a-a525-2baf25246495
# ╠═c3a0cceb-1c58-4463-9b3b-524fa0acd731
# ╠═a4439729-6e8e-4910-aed2-e893319b8b27
# ╠═68854811-b485-4222-ad9d-1a250199cc9d
# ╠═35a5c725-b392-4bf3-b6a0-bf81fa4883b4
# ╠═95e65a08-a149-42f7-a700-1f8364c3daec
# ╠═3e7bfb10-256e-43c6-994b-cfa9241e3dd8
# ╠═04e00e04-3d3a-4a58-a0cb-aeec26a10e85
# ╠═8906a937-3d18-49df-8c36-e4efe9146082
# ╠═dfe95808-a81e-48e0-8dc2-f831ef73c2bc
# ╠═8ce3aeb0-b7ac-4eb8-8ea8-0647c3860fc9
# ╠═eac76a23-99d9-4966-9e7b-5ba0635ef4b3
# ╠═6d6e2cf0-b40b-41d8-860b-46dcb1f2be0c
# ╠═9271189a-59d1-4da9-9264-61e26acef1f3
# ╠═efc84a10-aed4-4226-93f6-7110e1e68c30
# ╠═58d87521-20fb-4bbb-88fe-cf154122609b
# ╠═f619c741-7928-4fe5-b09a-04cb923bcc59
# ╠═289204ea-3678-48af-9f62-95938ce61c8b
# ╟─285b7d3f-43c3-48d7-95ab-26b73f0d3faa
# ╟─721480ef-e711-43f0-9b33-8ec21ec0b8c1
# ╠═76a454ef-ec9b-413d-a623-d072ab9c8b15
# ╠═561074b1-2e96-4f30-8489-6a8d36948289
# ╠═cc72a9bd-34a1-4998-b82f-8343f4b7cd06
# ╟─a07ff22d-d00b-4090-a93b-f0dd843174b3
# ╠═9bffc882-57b8-4b18-bce4-fc244a878159
# ╟─e6967961-0347-496a-9a75-0da8f07fda72
# ╠═cb17b891-77f8-4235-b9f1-25457b7eb4ff
# ╠═8c623cec-8b95-44ce-ab96-fab379c59808
# ╠═18056d05-e226-4e6c-9956-76fefe4dc8d6
# ╟─d6440ae7-176b-4858-ba14-28a1c95bc1d2
# ╠═fcba86e3-c129-4e07-a5fc-36dc9cb9815f
# ╠═a78f0eb0-289a-4381-adcc-49ba3b1ca516
# ╠═4960422c-d549-423d-9d2d-254851292a39
# ╠═99ecd111-48b2-47a2-81dc-254d62892f10
# ╠═47d46711-0d0b-4352-b6ec-e9315ca8d53a
# ╠═4d59ddaf-6bbe-4e6e-ae06-5d0d3e4f3053
# ╠═7676d4ef-4120-4379-9811-28c0f452f43c
# ╠═f8decbaf-57f5-40ce-b973-fa26932a947c
# ╠═572d8ee1-06b8-4d6d-9e7d-1ab4ff381af5
# ╠═7f89925f-4d3e-45ed-9ff5-2e86d24017df
# ╠═65e50610-3609-45fc-8de0-634c9309f518
# ╠═532b17bb-c751-4802-939b-e4340479b947
# ╠═8862154c-683b-4af6-8ee2-2b52be52579a
# ╠═81880c2b-f93b-4dd6-a593-9317faf2b0f4
# ╠═5ec50a1e-211b-4c25-8422-4774331c6a03
# ╠═d3c2e722-5793-4562-9a79-1ca8b6990e31
# ╠═ee54d9eb-be8b-4a76-9e45-fd6de6951b78
# ╠═444ca978-c7d7-4438-b8d1-5fb1401d7c1f
# ╟─f2d2d67d-925a-463a-8c5b-e4f3db1c2d9c
# ╟─a5e1da76-cbf7-4010-83d7-f4e23b7fbd6d
# ╟─accfe8d2-062a-4a7f-a0f2-3b0f0e92afc7
# ╠═427a28a3-901c-4f48-a3a8-bc62e59b4330
# ╠═874ae422-a71c-4d21-bbbc-80df197f8d40
# ╠═8b7d6dbb-b8fa-4f24-a97b-5d7f6f0bb90f
# ╠═69672719-b763-4cd3-a5d6-97bb74568fc7
# ╠═8335f6b5-49af-4b37-912f-ec0366dff307
# ╠═b06ad072-bafb-4dea-bb36-4438e7b449a8
# ╠═6b6dc645-c6f9-42eb-9eda-9f7dacc04fba
# ╠═3946e40f-0653-4df7-b646-13c28f96ce0b
# ╠═8f0605a2-3fc9-41d1-a68e-c8619c0b43f8
# ╠═899e37f9-a142-4298-bb74-4fc2f5ba6347
# ╠═5c8d88ee-d326-49db-a630-43699ad8cd0b
# ╠═9fac1906-f4ff-4d5e-afe2-e81caed07e97
# ╠═5dda9b4a-410d-4158-b647-4f3b882a1786
# ╠═e4986053-04ed-4011-bff6-c0b3a12ea608
# ╠═deb751b7-dcd5-4d47-9bfa-c90147db090c
# ╠═9c7a6e2b-8121-4217-8d4f-8690a29fae4e
# ╠═c4e91d3c-7abf-48bf-9d75-500ec6dccde0
# ╠═ea14c871-fa0e-4bc7-99ba-ebba0e4dbcb6
# ╠═b0a9692d-727b-4176-ac6b-e8c78c5c11cc
# ╠═0ba1fd65-ba7d-419e-b89a-93a314b99d66
# ╠═7bbca210-6ee3-4ef3-8444-e7645f558aea
# ╠═598c121a-171b-4422-80be-0fdbdbcee97e
# ╠═8e3eb976-9371-4b49-b7d6-2348098db36a
# ╠═f9907461-9f63-4a40-b373-5caba8bf32ad
# ╠═04eb7126-f28b-40a2-9408-304d3a3c7ef7
# ╠═128fae72-5eaa-48f9-b14b-486ac08a90c5
# ╠═8b4d22bb-3e73-4dd4-b24a-55b4067b22dc
# ╠═d33f3e17-a266-46f7-95c1-bb3421006ab2
# ╠═cfa5069c-377d-4cc1-aba4-ff891527ddd6
# ╠═ba886e67-0679-44dd-8208-5c92d625f75a
# ╠═ddf9acf5-f045-4250-88ff-94119d503cb8
# ╠═dad4f0d3-383d-431a-bb10-1431d509673e
# ╟─efa7fee0-55fa-472a-9bc3-f594c5dd924d
# ╟─452d0535-56ba-4023-963d-1f1aaf186285
# ╠═2858cd5e-3ad1-4b92-b38d-272e3f89ec55
# ╠═84dbfab3-32af-4255-b2e9-b78f2f91fdab
# ╠═ad6f09d8-0c8f-46c2-aca7-c9ba192e36b6
# ╠═4e728986-4425-49cb-834c-7b4b37c2d7bc
# ╠═fd3f7b7e-c6e1-4e3e-9733-a8ade2fd89da
# ╠═2b59ca2c-72b1-4365-b4bc-8bc6fff3877a
# ╠═1f25d5eb-a1bf-4981-ba72-6925de36151c
# ╠═0ad392fb-2c88-424f-a0a0-fc06c16c9f06
# ╠═3842c5d9-9e1b-4c92-bcb1-2e8542f43bcf
# ╠═6a4da1f2-c8a5-41b4-ada5-7547622b6269
# ╠═c8c2d551-c6a0-4555-8a78-26a644c2c30a
# ╠═83371c50-62da-46f3-84b7-2b76471faab1
# ╠═08bb567c-7e53-46f3-b4da-cff49099d0dd
# ╠═54736305-fdc0-4e63-8872-2c7ce5fcd369
# ╠═1bf1c95b-c72a-417b-8d1e-053108fc2c9b
# ╠═bdc0db73-b88b-40ad-b310-5389573fe77f
# ╠═71dcbd12-f573-4cb7-9c97-4d1fb4251ac0
# ╠═d27b601e-d968-456b-b83c-9111632e4f6f
# ╠═56a4e7b8-3537-4c1d-8b41-60691b549cc4
# ╠═26451125-a996-4ea2-ba79-ef186f7a6c17
# ╠═6c2a3e15-be2b-467f-80fb-b7ec89b42168
# ╟─100699a0-b09a-4790-9c7c-3ff2d831908b
# ╠═5f0ee59f-458e-48d5-bcd4-591f735e2596
# ╠═eb54ac0e-4135-4cdb-b0fe-0aff5dedbe79
# ╠═1fa64af2-1965-4748-8c79-78b62acf8060
# ╠═a067b798-795c-4a57-9079-f64cdc50d35d
# ╠═be6c5a27-755d-429e-8e1d-97c49ecb53c5
# ╠═9c623025-4b7c-4c64-b9a4-b1d8e7bb0e2f
# ╠═7448d912-79f8-41e9-ad93-e1e9b6d731b4
# ╟─e86fee65-a9ad-42b1-819c-1a965d4d3d8a
# ╠═4b59c851-3c19-481d-9919-3c18d8d2ace4
# ╠═fa04601d-bd70-4824-8342-87ee850a63d5
# ╠═a17c9fc2-63f1-4707-bdb9-0aa8da50a609
# ╟─e7e9d13b-8d82-4fca-b2fd-9b839207081e
# ╠═a9bf4f3d-25b2-4016-bfc8-ef8500bcd3e1
# ╠═23086bf0-54e0-4930-b161-5cca60e4166b
# ╠═2fa3add3-7247-4d5b-a08d-a4d2cec794f2
# ╠═4f35dc1d-0178-4456-adb7-c4fdfd5abe08
# ╠═fca97d6c-9baf-49ba-b346-28b9137c4471
# ╠═51043712-df90-4058-858f-b00fdb42177e
# ╠═ef261d67-219d-4004-8371-3c0dee1fe4b3
# ╠═69e46514-8bc7-4122-ad05-e3e95aa9a621
# ╠═c5a99a95-a4fd-40ff-a1a4-e0fed2dfb280
# ╠═ac31e8ae-a691-427d-83c2-82cefecf76e1
# ╠═2aa6658f-73b8-4fa1-98e1-dcda14b483ac
# ╠═21125794-7268-4388-8e34-71227ac65f1b
# ╠═c195d569-7274-45db-bc0d-817e4fc98bc4
# ╠═88c6340b-183b-4bc0-a71a-aa97125f1cd9
# ╟─b666987d-6bd3-41f4-a638-0d8ddfdda00c
# ╠═8f201720-902f-44ee-8ef8-a896730200b3
# ╠═1b29310c-8b2d-4bba-843f-f5790447707d
# ╠═086cf67b-009d-49f5-80b7-e8b9bd91337a
# ╠═58cf45d9-4e3e-4056-84ad-06a3efb682ca
# ╠═47eae398-661b-4a35-be30-16547c71fe7b
# ╠═b7085722-7a6e-4c74-980c-8f382dd20624
# ╠═d3cbdc82-7f95-4857-8cb0-55e6f294192e
# ╠═00e4b8d6-4c25-44f5-8f22-e448e861989e
# ╠═6034bdfe-d518-4880-b281-698f4b614bda
# ╠═f25d730c-639b-4ff0-9856-f0e14dbff23c
# ╠═616e845c-2cf7-47b5-bfa1-8a849072cf7b
# ╠═e5752416-2ebc-4ebc-bc65-711792763fd9
