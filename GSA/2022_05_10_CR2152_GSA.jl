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
	# using Plots
	# using Plots.PlotMeasures
	using Printf

	using CSV
	using DataFrames

	using NetCDF
	using Dates
	using LaTeXStrings
	using PlutoUI
	# using StatsPlots
end

# ╔═╡ dc90bbc7-c265-4850-9f13-71d9705d45be
begin
	using Revise
	include("/Users/ajivani/.julia/dev/GSA_CME/src/gsaUtilities.jl")
	include("../src/plotUtils.jl")
end

# ╔═╡ 64ba2df3-4dd4-44ff-acd4-d7c8f9dedb67
begin
	using MATLAB
	using Random
end

# ╔═╡ 3054bbd7-845d-4fc7-a8c0-7ab73d321457
begin
	using JLD
	# save("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapUr2152.jld", "UrBootstrap", UrBootstrap)
	# save("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapNp2152.jld", "NpBootstrap", NpBootstrap)
end

# ╔═╡ e734f80a-3792-4d32-ab20-34f85707a590
using Plots.PlotMeasures

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
	X_design = CSV.read("/Users/ajivani/Desktop/Research/MaxProDesignCME/designOutputs/X_background_CR2152_updated.csv", DataFrame)
	# rename!(X_design, :FactorBo => :FactorB0)
end

# ╔═╡ 003792f0-b399-4eba-8dd2-2da32b587219
begin
	lbBg = [0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1]
	ubBg = [2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2]
	
	paramsBgScaled = (X_design[!, 1:6] .- lbBg') ./ (ubBg' - lbBg')
end

# ╔═╡ 92b0f246-1b0f-4ce7-94a4-ebf54e95bf05


# ╔═╡ 46168df1-54af-4547-99c8-06b42a4ac864
extrema(Matrix(paramsBgScaled); dims=1)[:]

# ╔═╡ 09e9a23f-7c39-4ce4-9f57-d1c3b71dd07c
with_terminal() do 
	ncinfo("../data/bg_CR2152.nc")
end

# ╔═╡ dfbaccaf-66af-43ea-88d8-a6e9764b146f
begin

	fn = "../data/bg_CR2152.nc"
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

# ╔═╡ 5ab604d5-584c-4b25-9e31-39d6ae13749a
times

# ╔═╡ dde2906d-a892-48eb-abdf-836d2e555d22
md"""
### Plot sim and obs
"""

# ╔═╡ 332d1132-9de4-4908-8125-c0f1cb7d4277
additionalExcluded = [5, 23, 30, 31, 35, 39, 41, 42, 48, 49, 53, 64, 65, 69, 83, 85, 91, 93, 103, 105, 111, 112, 119, 141, 158, 159, 160, 162, 164, 167, 174, 178] # hard constraints
# additionalExcluded = [5, 23, 30, 31, 35, 39, 41, 42, 48, 49, 53, 64, 65, 69, 83, 85, 91, 93, 103, 105, 111, 112, 119, 141, 158, 159, 160, 162, 164, 167, 174, 178] # by eye

# ╔═╡ 21939cfe-d0b3-4ecb-9fd9-e6e83827456f
begin
	# exclude Ur by value first
	excludeUrList = []
	excludeNpList = []
	for i in 1:200
		push!(excludeUrList, findall(x -> x <=200 || x >= 900, UrSim[:, i]))
		push!(excludeNpList, findall(x -> x <=0   || x >= 100, NpSim[:, i]))
	end

	excludeUrIdx = []
	excludeNpIdx = []
	for i in 1:200
		if length(excludeUrList[i]) > 0
			push!(excludeUrIdx, i)
		end
		if length(excludeNpList[i]) > 0
			push!(excludeNpIdx, i)
		end
	end
end

# ╔═╡ f85afd7c-c127-4444-b407-1913c0b33cf4
excludeUrIdx

# ╔═╡ bf4c95d9-13c3-45e6-8024-ae99acd589a3
excludeNpIdx

# ╔═╡ 1d2a0cc4-6c09-4c3c-b13b-c5f2cc3e9455
excludeBothCriteriaOnly = intersect(excludeUrIdx, excludeNpIdx) # find only those runs that are bad in Ur and Np simultaneously, not one at a time

# ╔═╡ 5c144708-023e-460a-8a1a-431a4ad920a6
failedRuns = setdiff(1:200, successfulRuns)

# ╔═╡ 630fcdb2-ef98-4ae8-ad15-3ebfe37c4e00
excludedRuns = setdiff(setdiff(1:200, runsToKeep), failedRuns)

# ╔═╡ a7d9bc78-04bf-4404-83bc-db10c92e1cce
totalExcluded = unique([excludedRuns; additionalExcluded])

# ╔═╡ 1838ae27-128c-4bcf-9251-45dc4f79a5c7
success2KeepIDs = setdiff(1:200, unique([failedRuns; totalExcluded]))

# ╔═╡ ee388a1e-4068-494b-a097-6e1bdff74baf
# calculate RMSE naively (no shifting, or trimming involved and see if it matches "intuition")
begin
	using StatsBase
	rmseUr = [rmsd(UrSim[:, i], UrObs) for i in success2KeepIDs]
end

# ╔═╡ c18f5f64-72b9-4384-b1e6-858cfea0dd34
md"""
SIMID = $(@bind EachSimID MultiSelect([string.(successfulRuns[i]) => successfulRuns[i] for i in 1:length(successfulRuns)]))
"""

# ╔═╡ 444f5b42-fb30-47bc-9634-a69cfe13dcb2
EachSimID

# ╔═╡ 804fe8bf-8106-4885-8b65-72dab17539d1
minimum(UrSim[:, 187])

# ╔═╡ bf379789-7caa-4231-b5c2-b1f536e733ab
# begin
# 	pUrSimObs = plotSimObs(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsUr...)
# 	pNpSimObs = plotSimObs(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsNp...)
# 	pBSimObs  = plotSimObs(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsB...)
# 	plot(pUrSimObs, pNpSimObs, pBSimObs, layout=(1, 3), xlabel="", size=(1500, 800))
# 	plot!(xrot=10)
# 	plot!(title="All Successful")
# 	# plot!(xrot=25)
# end

# ╔═╡ 19fbe0ad-5541-4711-bde7-f96f4a07e3ab
md"""
ToKeepSIMID = $(@bind ToKeepSims MultiSelect([string.(success2KeepIDs[i]) => success2KeepIDs[i] for i in 1:length(success2KeepIDs)]))
"""

# ╔═╡ efc9ad22-b004-42c2-8adb-115024c42356
# begin
# 	savefig(pUrSimObs2, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/UrSims_CR2152.png")
# 	savefig(pNpSimObs2, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/NpSims_CR2152.png")
# 	savefig(pBSimObs2L, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/BSims_CR2152.png")
# 	savefig(pTSimObs2L, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/TSims_CR2152.png")
# end

# ╔═╡ 5e2d1470-c487-46ed-b08d-af4a265e977d
minimum(UrSim[:, 119])

# ╔═╡ 88fd5d74-437d-4ca9-a89f-95aa1dff0164
# md"""
# ExcludedSimIDs = $(@bind ExcludedSims MultiSelect([string.(excludedRuns[i]) => excludedRuns[i] for i in 1:length(excludedRuns)]))
# """
md"""
ExcludedSimIDs = $(@bind ExcludedSims MultiSelect([string.(totalExcluded[i]) => totalExcluded[i] for i in 1:length(totalExcluded)]))
"""

# ╔═╡ d6733c06-c6da-470e-bdba-6621816fc644
ExcludedSims

# ╔═╡ bdcfb800-c97c-4927-b2e3-e47bbe8def30
length(totalExcluded)

# ╔═╡ 4a6af1de-b5c4-4683-8627-d5f7f5953247
clusters_by_eye = [[5, 6, 11, 20, 23, 30, 31, 35, 42, 48, 74, 112, 120, 137, 142, 146, 149, 158, 159, 175, 178, 194, 54, 111, 146], # drops below observation in the middle
				   [14, 34, 41, 49, 53, 64, 65, 68, 69, 72, 83, 85, 88, 91, 93, 94, 103, 105, 117, 119, 141, 160, 162, 164, 167, 174],  # consistently less than observation for Ur
				   # [54, 111, 146, ]
				   [3, 25, 57, 121, 123, 151, 152,  170, 173], # mostly Np out of bounds
				  [124, 169] ## everything out of bounds
]

# ╔═╡ 9668f1bf-00a3-4396-82a1-bd8caca8c609
length(vcat(clusters_by_eye...))

# ╔═╡ 4e2b9048-08f9-4f95-a22a-540b553ec885
rmseUr

# ╔═╡ fe94fe6e-6c01-40a5-aaeb-e16865f127f6
X_design[179, :]

# ╔═╡ 3928276c-7518-421e-ab2b-259e3137917b
md"""
### Plot groups of runs for the excluded runs and see if we need to remove all of them from the analysis.

Nothing systematic here, just groups based on observation of how the trajectories behave compared to the observations. ("similar" runs by eye)
"""

# ╔═╡ 22f03ffa-14db-45f9-b48a-530852f8de50
md"""
We will also plot the runs where we only remove those that satisfy both Ur (< 200 >900) and Np(<0, > 100) simultaneously.
"""

# ╔═╡ ea27ad1a-0ad1-4500-a369-598beef3bd75
# savefig(pUr, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/filteredCR2152Ur.png")

# ╔═╡ b33ccfaf-31b4-4264-ab0f-99c0002610a5
# begin
# 	pUrS = plotSimObs(UrSim, UrObs, times, collect(1:200); simIdx=runsToKeep, plotArgsUr..., ylims=(0, 1100))
# 	pNpS = plotSimObs(NpSim, NpObs, times, collect(1:200); simIdx=runsToKeep, plotArgsNp..., ylims=(0, 120))
# 	pBS = plotSimObs(BSim, BObs, times, collect(1:200); simIdx=runsToKeep, plotArgsB...)
# 	plot(pUrS, pNpS, pBS, layout=(1, 3), xlabel="", size=(1500, 800))
# 	plot!(xrot=10)
# 	plot!(title="Runs Used")
	
# 	# plot!(xrot=25)
# end

# ╔═╡ 8e96c014-f34b-48d2-8c85-a40610a8725b
# begin
# 	pUrSModified = plotSimObs(UrSim, UrObs, times, collect(1:200); simIdx=setdiff(1:200, totalExcluded), plotArgsUr..., dpi=300, ylims=(180, 800))
# 	# savefig("/Users/ajivani/Downloads/UrSims.png")
# end

# ╔═╡ 5bd0e50a-6cac-471d-b29c-ab966777028b
# md"""
# ### GSA
# """

# ╔═╡ e9b604dd-72ec-49e1-9e28-087882252164
md"""
### With regularization
"""

# ╔═╡ 5a628c9d-7f2e-433a-bed1-b06d6ab7a9f6
lambdaVals = 10 .^(range(-2, 1.3, length=20))

# ╔═╡ cf4d6e5b-a087-4769-8f27-8e3bc1ef241e
times

# ╔═╡ 33bb4cf8-dbc5-44d0-92ba-e7ce463984a7


# ╔═╡ f2a3e375-1f96-4f1e-b8d7-4069c61d4afb
findall(in([DateTime("2014-07-04T18:00:00")]), times)[1]

# ╔═╡ 60f018c3-6142-4b39-ad7c-bed05d656afa


# ╔═╡ 602c78ae-8198-4661-9042-050dea15a173
md"""
### Without regularization
"""

# ╔═╡ 78eeb3d4-0528-4253-802f-d164e47e759e
begin
	# X = Matrix(paramsBgScaled[runsToKeep, :])
	# Y1 = Array{Float64, 2}(UrSim[:, runsToKeep]') # commenting out for now since runsToKeep definition is not proper here. need further look at runs removed in new analysis
	# Y2 = Array{Float64, 2}(NpSim[:, runsToKeep]')

	X = Matrix(paramsBgScaled[success2KeepIDs, :])
	Y1 = Array{Float64, 2}(UrSim[:, success2KeepIDs]')
	Y2 = Array{Float64, 2}(NpSim[:, success2KeepIDs]')
	# Y = 
end

# ╔═╡ 3814a593-8cfd-4dcb-a8f5-2320c29b3f6f
kFoldErrorsUr = kFoldCV(X, Y1, lambdaVals; pceDegree=2, nFolds=5)

# ╔═╡ 122b28d6-52a2-4323-9724-fc0e4d33d591
lambdaOptIdxUr = [argmin(kFoldErrorsUr[i, :]) for i in 1:length(times)]

# ╔═╡ 58c4cf32-b6d2-4d34-8a82-d77083399268
lambdaOptUr = lambdaVals[lambdaOptIdxUr]

# ╔═╡ f6aab539-3fe6-4493-8b71-7e10ce7d77c9
kFoldErrorsNp = kFoldCV(X, Y2, lambdaVals; pceDegree=2, nFolds=5)

# ╔═╡ a0a9d522-81d2-4e23-b6fa-2616636a5af8
begin
lambdaOptIdxNp = [argmin(kFoldErrorsNp[i, :]) for i in 1:length(times)]
lambdaOptNp = lambdaVals[lambdaOptIdxNp]
end

# ╔═╡ 00241acf-85d3-4a6b-b211-96500d1d4dbb
lambdaOptNp

# ╔═╡ f8c9cd60-b7b2-44fc-8877-a6956ed90aed
lambdaOptNp[149:173]

# ╔═╡ fb7a2484-c2d5-4b4f-bab5-13c37643cc5c
gsaRegNp = gsaRegularized(X, Y1, lambdaOptNp; pceDegree=2)

# ╔═╡ 17a9bf78-9dc8-4bf1-aca0-5baf125354ff
gsaRegUr = gsaRegularized(X, Y1, lambdaOptUr; pceDegree=2)

# ╔═╡ 1b433f43-9b84-41b8-9ca2-10539b403258
begin
	mainEffectsRegUr = processMainEffects(gsaRegUr)
	mainEffectsRegNp = processMainEffects(gsaRegNp)
end

# ╔═╡ 3414a1d0-f9c1-474d-abec-dcefc143ea17
begin
	meanUrReg, stdUrReg = getConfidenceIntervalsVar(X, Y1, lambdaOptUr)
	meanNpReg, stdNpReg = getConfidenceIntervalsVar(X, Y2, lambdaOptNp)
end

# ╔═╡ 610e5d6a-3184-4e00-ab47-85aa1e8979c8
plotMeanStd(Y1, meanUrReg, stdUrReg, UrObs, times, nSTD=2, trimIndices=(1, 577))

# ╔═╡ ba8c0fc2-9e23-49d1-8af9-2ff8321cdf5f
plotMeanStd(Y2, meanNpReg, stdNpReg, NpObs, times, nSTD=2, trimIndices=(1, 577))

# ╔═╡ 48998320-efca-4032-892a-7ac3d4d48a65
size(X)

# ╔═╡ 7828d7a1-8f9e-4625-9656-0f00d881c900
size(Y1)

# ╔═╡ 04ff14d0-d714-4700-b03c-017d4fd4f759
size(Y2)

# ╔═╡ ee362fc8-1c74-4561-b1d8-db94d0648e96
# build coefficient matrix!
A = buildCoefficientMatrix(X; pceDegree=2)

# ╔═╡ 037787ec-9a84-4483-87c5-5a8a44c1287e
size(Y1)

# ╔═╡ bbdcc6ba-e6ae-470b-8b51-9ebbaa8b2a5f
begin
	gsaIndicesUr = gsa(X, Y1; regularize=false, pceDegree=2)
	gsaIndicesNp = gsa(X, Y2; regularize=false, pceDegree=2)
end

# ╔═╡ 7163eb32-198a-4589-94fc-5ad4a040bcb8
begin
	meanUr, stdUr = getConfidenceIntervals(X, Y1; regularize=true, lambda=0.3, pceDegree=2)
	meanNp, stdNp = getConfidenceIntervals(X, Y2; regularize=true, lambda=0.9, pceDegree=2)
end

# ╔═╡ 80a1ab37-2b49-41cf-8397-7ddce37356b1
begin
	plotMeanStd(Y1, meanUr, stdUr, UrObs, times, nSTD=2, trimIndices=(1, 577))
	# savefig("/Users/ajivani/Downloads/Ur2152Uncertainty.png")
end

# ╔═╡ 46936905-0c76-4d6e-8e56-ed00a0abc87f
begin
	plotMeanStd(Y2, meanNp, stdNp, NpObs, times, nSTD=2, trimIndices=(1, 577), ylabel="Np")
	# savefig("/Users/ajivani/Downloads/Np2152Uncertainty.png")
end


# ╔═╡ 904c8009-7574-4786-9110-4d81eeae3078
md"""
### Plot surrogate predictions

Here, we will calculate PCE coefficients for given data-input matrix pairs and use those to obtain surrogate predictions at new test samples. We will use those to construct a sort of violin plot for the uncertainty estimates to give a more representative uncertainty envelope (skewed toward positive side).
"""

# ╔═╡ caa03923-fb76-4fbb-97fa-8180838df025
begin
	mainEffectsUr = processMainEffects(gsaIndicesUr)
	mainEffectsNp = processMainEffects(gsaIndicesNp)
end

# ╔═╡ 16f9b679-e8c5-4425-ab3e-ef8afd36f7f5
inputNames = names(paramsBgScaled)

# ╔═╡ 622e3e50-ad66-4c93-8858-90cdccafb046
md"""
For surrogate predictions, we will generate new samples from a MaxPro design, again keeping in mind that we want to constrain it correctly. We will call the generated designs directly from the `MaxProDesignCME` repo. 

It is notable that this is only a trial run at plotting uncertainties, and we may have to do it with a lot more than the 200 we are starting with.

It may be wise to revisit the constraints we put. For eg, removing only those runs where both Ur and Np are bad as opposed to only one of them would be more restrictive and probably more justifiable too? since we are considering both QoIs for sensitivities. 
"""

# ╔═╡ 6817d63a-f131-4b1f-bdda-78acae8129e3
XTestMax = load("../../MaxProDesignCME/designOutputs/SolarMax2152Test.jld", "XTestMax")

# ╔═╡ 2dcd078b-e3ed-41da-ae8f-167e12f01f56
begin

# do latin hypercube sampling here, and build a bigger test set
end

# ╔═╡ 8c7f863e-11a3-48f3-9f05-25c5a8be5fc8


# ╔═╡ 49f2ce13-769e-464c-8deb-68caec732c01


# ╔═╡ 74c1f916-6460-4f6c-ba2a-cfbcc5b9a274
inputNames

# ╔═╡ dd0fc3fa-b1b0-40fe-b029-4cc5c8e27f14
# let's remove some of the datapoints from XTestMax. Scale up the XTestMax values to the original ranges.
begin
# lbBg = [0.54, 2e17, 0.3e6, 0.3e5, 0.1, 1]
# ubBg = [2.7, 5e18, 1.1e6, 3e5, 0.34, 1.2]
XTestMaxScaled = (XTestMax[:, 1:6]) .* (ubBg' - lbBg') .+ lbBg'
end

# ╔═╡ 1c6bdaea-ffbe-4cea-a417-c871a52b49df
filterPFThreshold = 5e5

# ╔═╡ 9be19580-76b6-45c2-a310-57a097568a9f
filterIdxXTest = findall(x -> x <= filterPFThreshold, XTestMaxScaled[:, 3])

# ╔═╡ 0b4c8486-d690-4d92-b381-fcb7803a774c
XTestMaxScaledFiltered = XTestMaxScaled[XTestMaxScaled[:, 3] .<= filterPFThreshold, 1:6]

# ╔═╡ 6d1ddac9-6f56-410d-a555-f1a44d42ff7c
begin
	scatter(XTestMaxScaled[:, 1], XTestMaxScaled[:, 3])
	scatter!(XTestMaxScaledFiltered[:, 1], XTestMaxScaledFiltered[:, 3])
end

# ╔═╡ f5ec311a-827b-4c6a-b00c-b14d88d58dfa
ATest = buildCoefficientMatrix(XTestMax[:, 1:6]; pceDegree=2)

# ╔═╡ e3922291-a186-44ef-8d31-d10e8c83a51e
ATestFiltered = buildCoefficientMatrix(XTestMax[filterIdxXTest, 1:6]; pceDegree=2)

# ╔═╡ 41ffe6bf-e8be-4ed7-a7e5-83c28e58405c


# ╔═╡ 639559f8-874c-4e40-ba48-9269af6d018d


# ╔═╡ 82afb408-6202-4431-b6f2-fc24ef9efe72


# ╔═╡ 88b2538a-db0f-445c-a633-3e6f1cf2458b
betaUr = solveRegPCE(A, Y1; λ=0.3)

# ╔═╡ 544c74f8-e2ad-4cae-80d0-fbccc91245a8
betaNp = solveRegPCE(A, Y2; λ=2)

# ╔═╡ f1894ca0-2dc2-425b-b0b2-0a792576a4e9
md"""
Here surrogate predictions are plotted with regularization.
"""

# ╔═╡ bdf41290-1f0b-4d6d-82ab-13b13f90e798
begin
	betaNpReg = solveRegPCEVar(A, Y2, lambdaOptNp)
	yPredNpReg = Matrix((ATestFiltered * betaNpReg)')
end 

# ╔═╡ 7fcd9c33-b383-4cdb-846b-3bfd502e8f32
nPred = size(yPredNpReg, 2)

# ╔═╡ 63e0448d-d15d-4534-9419-f97299fbdea0
md"""
here surrogate predictions are plotted without regularization
"""

# ╔═╡ 9bfcc241-e866-4413-8ea1-5996cfb8a8cd
# @bind selectNp Slider(1:134, default=60, show_value=true)

# ╔═╡ 416c1a7b-c626-4e0c-b72a-8434d297a403
@bind selectNp MultiSelect(string.(collect(1:nPred)))

# ╔═╡ ed116fd1-324f-49a2-b78a-5922be061ae8
# @bind highlightNp Select(string.(collect(1:118)))
@bind highlightNp Slider(1:nPred, default=1, show_value=true)

# ╔═╡ 58cee74a-e123-4e10-8196-42903bb41127
begin
	meanEmpiricalNp = mean(yPredNpReg; dims=2)
	stdEmpiricalNp = std(yPredNpReg; dims=2)[:]
end

# ╔═╡ bcccb27a-5625-4009-a133-823af9d762e5
begin
	pMeanStdNpReg = plotMeanStd(Y2, meanEmpiricalNp, stdEmpiricalNp, NpObs, times, nSTD=1, trimIndices=(1, 577))
	vline!([222, 426], line=(:red, 1), label="")
	# violin!(repeat([222, 426], inner=118), yPredNpReg[[222, 426], :][:], linewidth=0, fillalpha=0.7)
	# plot!()
end

# ╔═╡ 99c8bd6c-5a17-4e5c-a509-f0987f78c667
violin(repeat([100, 200], inner=118), yPredNpReg[[222, 426], :][:], linewidth=0)

# ╔═╡ 376271a2-9eb1-4a20-a2e4-b8177ca3806a
yPredNpReg[[222, 426], :][:]

# ╔═╡ 02d3beba-75da-4ebd-920a-6db09e0cfd4c
repeat([1, 2, 3], inner=100)

# ╔═╡ 06388b97-ccc1-4257-bb22-edf565f3a87f


# ╔═╡ 4feb37dc-0197-4441-8a02-8ea4c1e09c3d
begin
# 	# using StatsPlots
	StatsPlots.plot(repeat([1, 2], outer=10), randn(20), seriestype=:violin, label="Random violin plots")
	# now plot something else on top of this
	
end

# ╔═╡ 2c6c6efd-e488-4950-9b8d-8373ff3f73cf
violin

# ╔═╡ db32cfc3-b6b6-4575-b9ca-8d2f73f740ca
sortperm(stdEmpiricalNp, rev=true)

# ╔═╡ 90c02493-6af0-4553-adb0-9938d120ba1a
stdEmpiricalNp[222]

# ╔═╡ c208c13d-d673-466f-a3c1-6b3a3005ef51
stdEmpiricalNp[427]

# ╔═╡ 409c7fce-ba47-4a72-9ba6-b90b2bbc1653
# # need to make dotplots / violinplots to properly gauge how the uncertainty looks like. Also need to shade things at 1σ, 2σ, 3σ and so on. these figures can just be repeated for solar minimum. let's make it at some of the points with high uncertainties. 

# begin
# 	using StatsPlots
	
# end

# ╔═╡ 9ee2717e-6b55-4f5d-b296-bbd2a07d651b
# Use betaUr and betaNp already calculated to give predictions of Ur and Np.
begin
	yPredUr = Matrix((ATest * betaUr)')
	yPredNp = Matrix((ATestFiltered * betaNp)')
end

# ╔═╡ acd0a5cb-b22c-4771-9d58-ad6cc0669aa1
betaNp

# ╔═╡ ef694de8-8a0f-437d-8820-d7ad71576e0f
begin
	# center ATest and remove column of 1s since we will just add back mean(y)
	ATestFilteredCoeffs = ATestFiltered[:, 2:end]
	ATestFilteredC = ATestFilteredCoeffs .- mean(ATestFilteredCoeffs, dims=1)
	yPredNpCentered = betaNp[1, :] .+ Matrix((ATestFilteredC * betaNp[2:end, :])')
end

# ╔═╡ 74ed854a-b645-40ff-98a0-1f5e25ef5892
# repeat the process for the regularized predictions!
yPredNpRegCentered = betaNpReg[1, :] .+ Matrix((ATestFilteredC * betaNpReg[2:end, :])')

# ╔═╡ 05f6a153-4982-438b-9414-1ae4d2299856
plot(yPredNpCentered, label="")

# ╔═╡ f70769b6-8c7d-4ef6-a9d2-cd0a7209af3c
begin
	meanEmpiricalNpC = mean(yPredNpCentered; dims=2)
	stdEmpiricalNpC = std(yPredNpCentered; dims=2)[:]
end

# ╔═╡ fa366eb6-e55f-4c4a-b027-ba978e5d986a
pMeanStdNpRegCentered = plotMeanStd(Y2, meanEmpiricalNpC, stdEmpiricalNpC, NpObs, times, nSTD=2, trimIndices=(1, 577))

# ╔═╡ 4514ab64-4d9f-4ae8-a88f-91ee4137db47
plot(yPredNpRegCentered, label="")

# ╔═╡ 82325283-9ff3-44c7-bf23-057d60b95081
plot(yPredUr, label="")

# ╔═╡ 76a40fd1-c010-4016-99b8-a597a12f7ad7
md"""
Repeat process for Ur
"""

# ╔═╡ beccb9ff-6ef4-42f5-82a4-aaa7384d6673
yPredUrCentered = betaUr[1, :] .+ Matrix((ATestFilteredC * betaUr[2:end, :])')

# ╔═╡ e7e23a9b-6191-46f5-9b8f-25f534888313
plot(yPredUrCentered, label="")

# ╔═╡ e61fce66-e4cc-4f2e-b19b-8a00807e043d
md"""
### Use MATLAB ridge functions to cross-check answers
"""

# ╔═╡ 06e78ad9-3f3f-4a2f-8649-0b9e73e4003d
begin
	a = rand(MersenneTwister(0), 5, 3)
	am = mxarray(a)
end

# ╔═╡ db2bc0cf-07dc-432b-b74a-adb9dca6852b
a

# ╔═╡ bbcfb9fc-97b8-445b-8d52-9d9ccd6d5690
is_double(am)

# ╔═╡ d2915f20-7ad1-463b-8ed0-aca5cc227967
aj = jmatrix(am)

# ╔═╡ 6183e222-e6fd-4280-a79a-df049f28701d
begin
	# use MATLAB engine to evaluate expressions in MATLAB. Specifically, we want to use the ridge function.  
	bCoeffsRidgeNp = zeros(29, 577)
	for i in 1:577
		bCoeffsRidgeNp[:, i] = mxcall(:ridge, 1, Y2[:, i], A, 0.3, 0)
	end
end

# ╔═╡ 65e8b2d5-f193-4986-b20c-6a86798bc036
bCoeffsRidgeNp

# ╔═╡ 388f6e42-8a10-458c-9b23-9e16db45db82
yhatRidgeNp = bCoeffsRidgeNp[1, :] .+ Matrix((ATestFiltered * bCoeffsRidgeNp[2:end, :])')

# ╔═╡ 65a1479c-f549-46a2-a274-7849c4a5b521


# ╔═╡ 9aba231a-0606-4721-ad14-745d40b13bd8
plot(yhatRidgeNp, label="")

# ╔═╡ afe15611-4779-47f7-9517-f6bd71021ca0
mxarray(rand(6, 4))

# ╔═╡ ddd232f7-9974-482a-ba57-f35ce8cca9dc
mxcall(:ridge, 1, Y2[:, 1], A[:, 2:end], 0.3, 0)

# ╔═╡ 27590e20-a91b-4e1b-8a69-ac2373849a9f
md"""
### Sensitivity plots for no reg setting
"""

# ╔═╡ 185d1a7f-b524-4d2f-8b08-02c20b5c7dc5


# ╔═╡ a0726b0a-5864-4323-869c-fb9d3b533473
md"""
Time = $(@bind timeIdx Select([string.(i) => i for i in 1:length(times)]))
"""

# ╔═╡ 60e83fd4-6cbe-4e4a-a525-2baf25246495
timeIdx

# ╔═╡ c3a0cceb-1c58-4463-9b3b-524fa0acd731
# Time = $(@bind timeIdx Slider(1:length(times), default=1, show_value=true))

# ╔═╡ bb581139-1ae3-4347-80f1-426178c4a47b
gsaIndicesUr

# ╔═╡ 0413e2d7-25b2-4d16-b6bd-f5de2f66857d
interactionsUr = mean(gsaIndicesUr, dims=3)[:, :, 1]

# ╔═╡ ab6bbe39-88e3-46e6-b336-c45ba835e046
interactionsNp = mean(gsaIndicesUr, dims=3)[:, :, 1]

# ╔═╡ dfe95808-a81e-48e0-8dc2-f831ef73c2bc
# savefig(pUrIntMean, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/new/IE2152Ur.png")

# ╔═╡ 27c86d35-b0a4-4512-9e95-c0caba794336
md"""
### Final Plots and Settings for solar maximum

Whatever is in this section will go into the paper, nothing else. So make sure its watertight

- Only removing runs that are bad for both Ur and Np simultaneously, not otherwise - will have to justify this properly. But its ok for now we just make figures, and we can redo the analysis if so required.

- Single regularization setting for both quantities

- Generate a test matrix of 1000 points, use all of them for showing uncertainties from the surrogate predictions. Show boxplots at selected points, else keep the +/- 2σ gap everywhere.

- Finally, get the sensitivity plots, try to plot only one half of the interaction matrix

- We may have to redo the bootstrapping plots as well.

- Make new scatterplots of full param space.

- Then repeat all of the above for solar minimum setting

- Put all of this plus any other preprocessing needed in a separate repo 
"""



# ╔═╡ 52234463-2fc7-468c-9aeb-40373336ada8
md"""
Set regularization, and get beta values
"""

# ╔═╡ cf290101-b1b1-44b7-b6d5-9c9c09ab1d54
excludeBothCriteriaOnly # this includes failed runs too - 16, 50, 101, 126, 198

# ╔═╡ 81b9522b-c15b-45af-b690-e2de1ac93e2f
md"""
Find successful run set
"""

# ╔═╡ 1269827a-7615-48e1-917e-cda866c0694a
successBothCriteria = setdiff(1:200, excludeBothCriteriaOnly)

# ╔═╡ 2afbb8b8-bd7b-4817-9904-c0ed1125e5ad
md"""
Build coefficient matrix and solution matrices for Ur and Np on the basis of the above.
"""

# ╔═╡ 4dcc5e03-a682-4ddd-8c0b-f2dfb2b5f28d
begin
	XTrainFinal = Matrix(paramsBgScaled[successBothCriteria, :])
	YTrainUr = Array{Float64, 2}(UrSim[:, successBothCriteria]')
	YTrainNp = Array{Float64, 2}(NpSim[:, successBothCriteria]')
end

# ╔═╡ b360e2ce-c208-4c93-9698-8ad61295a8b3
# build coefficient matrix!
ATrainFinal = buildCoefficientMatrix(XTrainFinal; pceDegree=2)

# ╔═╡ 9c708c32-d76f-481a-9e07-8d4d3f2f8c79
md"""
Get PC coefficients for Ur and Np
"""

# ╔═╡ 336ca4b6-ec6e-4f65-8ad1-a7d2dfa70eaa
md"""
Get sensitivity indices
"""

# ╔═╡ ef3b3bb5-f6ce-480b-9af9-934ba8c14b6d
lambdaUrFinal = 0.4

# ╔═╡ 718a7d76-83dc-42fb-943c-f030bab68567
betaUrFinal = solveRegPCE(ATrainFinal, YTrainUr; λ=lambdaUrFinal)

# ╔═╡ b828966d-fc34-4769-849c-3207f9c386b0
lambdaNpFinal = 5

# ╔═╡ 910ebc66-fc43-4a11-a6b4-e51aa578b57b
betaNpFinal = solveRegPCE(ATrainFinal, YTrainNp; λ=lambdaNpFinal)

# ╔═╡ 7e8dc59a-c268-4cd2-a57b-15c3ba93bfa0
begin
	gsaUrFinal = gsa(XTrainFinal, YTrainUr; regularize=true, pceDegree=2, lambda=lambdaUrFinal)
	gsaNpFinal = gsa(XTrainFinal, YTrainNp; regularize=true, pceDegree=2, lambda=lambdaNpFinal)
end

# ╔═╡ 544fd1b0-677a-442a-9b6d-f5f0e6bfdafc


# ╔═╡ ff361325-a00c-4075-9039-2d0fa698ada1
begin
	gsaMainUrFinal = processMainEffects(gsaUrFinal)
	gsaMainNpFinal = processMainEffects(gsaNpFinal)
end

# ╔═╡ 7ca28df4-a1b3-4f68-bdba-a85801b4189f
md"""
Now generate test predictions!! For this load a test matrix saved at a suitable location.
"""

# ╔═╡ f0b5524c-48b2-4ddf-bf52-5cbf77e762a6
XTestFinal = load("../../MaxProDesignCME/designOutputs/CR2152TestFinal.jld", "XTestFinal")[:, 1:6]

# ╔═╡ 72fccc1d-8e90-4934-b8be-b0f23744032a
md"""
Optionally apply filter to only keep test points with a certain PoyntingFlux
"""

# ╔═╡ 578a9d43-15c9-432a-9c7f-482dd51dbd59
XTestFinalScaled = (XTestFinal[:, 1:6]) .* (ubBg' - lbBg') .+ lbBg'

# ╔═╡ ad018877-3066-4e1b-aff4-6cdc72d7a759
ATestTemp = buildCoefficientMatrix(XTestFinal[:, 1:6]; pceDegree=2)

# ╔═╡ e9c4d5c9-4966-4d93-91ed-fbaf2043e2b4
PFThresholdFinal = 6e5

# ╔═╡ abad3302-fd97-48ec-8390-d060cbfa7a51
filterIdxATest = findall(x -> x <= PFThresholdFinal, XTestFinalScaled[:, 3])

# ╔═╡ fcafd6ee-0f75-4e9b-9229-1e15a9530ec3
filterTest=false

# ╔═╡ f3373416-8749-40c5-aa40-48b6318d28db
if filterTest
	ATestFinal = ATestTemp[filterIdxATest, :]
else
	ATestFinal = deepcopy(ATestTemp)
end

# ╔═╡ 1b1df0d6-68a5-48b2-8eca-a88cf01a4968
begin
	ATestFinalFilteredCoeffs = ATestFinal[:, 2:end] # remove constant vector of ones
	ATestFinalFilteredC = ATestFinalFilteredCoeffs .- mean(ATestFinalFilteredCoeffs, dims=1)
	yPredNpFinal = betaNpFinal[1, :] .+ Matrix((ATestFinalFilteredC * betaNpFinal[2:end, :])')
	yPredUrFinal = betaUrFinal[1, :] .+ Matrix((ATestFinalFilteredC * betaUrFinal[2:end, :])')
end

# ╔═╡ f90eb10b-06cb-4957-b3be-c99799f4cb42


# ╔═╡ 85f39208-97f5-4435-9acb-7eebb8102ff1
plot(yPredNpFinal, label="")

# ╔═╡ 8fbdcf3d-9534-4d61-98d8-e5ef1b1d12a0
plot(yPredUrFinal, label="")

# ╔═╡ a0e8520c-c53b-4829-9644-8318364a624d
yPredUrFinal

# ╔═╡ 626dfee8-d0ce-4f61-9f7b-44c0be92bcc6
md"""
Now make the uncertainty plots - we want something like a violin or a boxplot overlaid on top of the usual 2 SD plots. We will start with a violin and then put everything else on top. We will also call a helper function written at the bottom of this notebook for convenience.
"""

# ╔═╡ 53e65a9e-1198-4cbe-975c-fcf42e9bcfd2
begin
	meanEmpiricalNpFinal = mean(yPredNpFinal; dims=2)
	stdEmpiricalNpFinal = std(yPredNpFinal; dims=2)[:]

	meanEmpiricalUrFinal = mean(yPredUrFinal; dims=2)
	stdEmpiricalUrFinal = std(yPredUrFinal; dims=2)[:]
end

# ╔═╡ 358923ce-1f30-41da-9820-20e60a23f278
md"""
We will try a boxplot at selected points. Changing the bar width should hopefully enable properly spaced out boxes. 

Reference: [Stack Overflow](https://stackoverflow.com/questions/71456841/statsplots-boxplot-decrease-width-of-boxes)
"""

# ╔═╡ b564669e-f312-4f37-ab88-8cd4487e6a00
md"""
Questions to address: Do we still want to keep 1.5 IQR? this is not necessarily relevant for highly asymmetric distribution. May just want to show violin plots instead but at fewer locations since it messes up width so badly.

can also try pyplot like functionality since we can apparently control the width of the violins.
"""

# ╔═╡ 7678c74b-8d19-423c-acf5-e404f39b822f
md"""
Also **very important**: Make an alternative plot that doesn't show mean + / - 2sigma but just violin and boxplot combo.
"""

# ╔═╡ f727dd62-cc94-4495-95a4-95fa7931bb9d
# begin
# 	nPredTest = size(yPredNpFinal, 2)
# 	densitiesToPlot = 1:30:577
	
# 	uncertaintyNp = plot(meanEmpiricalNpFinal, line=(:blue, 3), label="Mean of predictions")
		

# 	startTimeUncertainty, obsTimesTrimmed = processTimeInfo(times; trimIndices=(1, 577))
#     obsTimeTicksUncertainty = range(obsTimesTrimmed[1], 
#                         obsTimesTrimmed[end], 
#                         step=Hour(84)
#                         )
#     xTicksUncertainty = findall(in(obsTimeTicksUncertainty), obsTimesTrimmed)
#     uncertaintyLabels = Dates.format.(obsTimeTicksUncertainty, "dd-m")
# 	plot!(size=(800, 500))
# 	plot!(meanEmpiricalNpFinal, grid=false, ribbon=2*stdEmpiricalNpFinal,
#         line=(:red, 3),
#         # ribboncolor=:blues,
#         fillalpha=0.5,
#         xticks=(xTicksUncertainty, uncertaintyLabels),
#         xlims=(1, length(obsTimesTrimmed)),
#         label="μ +/- 2σ for constructed PCE",
# 		# fillcolor=:orange
#     )
#   	plot!(1:577, NpObs[1:577], line=(:black, 3), label="OMNI")
# 	boxplot!(repeat(densitiesToPlot, inner=nPredTest), yPredNpFinal[densitiesToPlot, :][:], 
# 		label="", 
# 		bar_width=120/length(densitiesToPlot), 
# 		outliers=false, 
# 		fillcolor=:orange,
# 		fillalpha=0.7,
# 		whisker_range=1.5)
# 	plot!(grid=true, framestyle=:box)
# 	# violin!(repeat(densitiesToPlot, inner=nPredTest), yPredNpFinal[densitiesToPlot, :][:], side=:right, label="")
# end

# ╔═╡ 1b4e28e4-0dae-4f4b-a38e-ba7a98d6923d
# begin
# 	# nPredTest = size(yPredNpFinal, 2)
# 	# densitiesToPlot = 1:30:577

# 	# everything shown below is converted into a function
# 	uncertaintyUr = plot(meanEmpiricalUrFinal, line=(:blue, 3), label="Mean of predictions")
# 	plot!(size=(800, 500))
# 	plot!(meanEmpiricalUrFinal, grid=false, ribbon=2*stdEmpiricalUrFinal,
#         line=(:red, 3),
#         # ribboncolor=:blues,
#         fillalpha=0.5,
#         xticks=(xTicksUncertainty, uncertaintyLabels),
#         xlims=(1, length(obsTimesTrimmed)),
#         label="μ +/- 2σ for constructed PCE",
# 		# fillcolor=:orange
#     )
#   	plot!(1:577, UrObs[1:577], line=(:black, 3), label="OMNI")
# 	boxplot!(repeat(densitiesToPlot, inner=nPredTest), yPredUrFinal[densitiesToPlot, :][:], 
# 		label="", 
# 		bar_width=120/length(densitiesToPlot), 
# 		outliers=false, 
# 		fillcolor=:orange,
# 		fillalpha=0.7,
# 		whisker_range=1.5)	
# 	plot!(grid=true, framestyle=:box)
# 	# violin!(repeat(densitiesToPlot, inner=nPredTest), yPredNpFinal[densitiesToPlot, :][:], side=:right, label="")
# end

# ╔═╡ 175f2ebc-fb8b-4b5e-97f0-7ad7a101e3d1


# ╔═╡ ae8305fa-a6b3-4d97-8ffc-2db511dfce38
md"""
Plot using the function `plotUncertainty`
"""

# ╔═╡ 7c675aa7-aafa-4d47-a919-4926ad79e6f1


# ╔═╡ af6dbc72-ea9f-4fb9-837f-d682a19bf3d2
function plotUncertainty(Y, meanPCE, stdPCE, obsData, timeData;
                    nSTD = 2,
                    ylims=(200, 900), 
                    ylabel="Ur",
                    trimIndices=(1, 720),
                    obsIdxToPlot=1:577,
					densitiesToPlot=1:30:557,
                    tickStep=84,
                    tickFormat="dd-m",
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

# ╔═╡ 99dfc8a0-fe0f-4ca1-80fe-7a51f2f7514d
begin
	plotUncertainty(yPredUrFinal, meanEmpiricalUrFinal, stdEmpiricalUrFinal, UrObs, ylabel="Uᵣ [km/s]", times, nSTD=2, trimIndices=(1, 577))
	plot!(guidefontsize=20)
	plot!(tickfontsize=15)
	plot!(legend=:topleft)
	plot!(left_margin=3mm)
	plot!(bottom_margin=3mm)	
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/cr2152_uncertainty_boxplots_ur.png")
end

# ╔═╡ 2e0dd925-5b56-456d-bfe5-ccb51e4d063d
begin
	plotUncertainty(yPredNpFinal, meanEmpiricalNpFinal, stdEmpiricalNpFinal, NpObs, ylabel="Nₚ [cm⁻³]", ylims=(-20, 120), times, nSTD=2, trimIndices=(1, 577))
	plot!(guidefontsize=20)
	plot!(tickfontsize=15)
	plot!(legend=:topleft)
	plot!(left_margin=3mm)
	plot!(bottom_margin=3mm)	
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/cr2152_uncertainty_boxplots_np.png")
end

# ╔═╡ 96269e36-0281-481c-a61c-e457cd8b7919
md"""
The distribution is even more skewed towards positive values when we try to restrict the range in the test. Keeping all points for now, but can follow up and ask if its more appropriate to present restricted test set results.
"""

# ╔═╡ bdcc23a7-fad1-41bb-ba6c-9a5a4b5aa48f
md"""
Now its time for the sensitivity plots
"""

# ╔═╡ bf421819-3a18-48f4-9b7c-492d5a1c8f66


# ╔═╡ ea8e0ebd-264a-44c9-9eff-1dab660d11d4
# savefig(pMainUrFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2152_ur_me_final.png")

# ╔═╡ c161f062-04a1-4710-afde-9f31a285b02c
# savefig(pMainNpFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2152_np_me_final.png")

# ╔═╡ a5365491-4e27-45b9-b298-8c01714b320d


# ╔═╡ 02a2c315-558d-4a6b-9cd5-5864f43297c5


# ╔═╡ 342ff748-c86b-4347-8592-0254a4889668


# ╔═╡ 0d58abdc-98f4-462d-b027-e21efdc34376


# ╔═╡ bfc25d2f-ced2-49ad-9ee6-75c5c89d4b13


# ╔═╡ 81c19f22-62a2-4f14-a3e0-80adaa8de7dd


# ╔═╡ 1dd25ff2-d375-4441-b635-327ebbd42f8b
# savefig(pUrIntMeanFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2152_ur_ie_final.png")

# ╔═╡ 6e346efd-9b7f-48e3-bcd1-33103e43c9c5
# savefig(pNpIntMeanFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/cr2152_np_ie_final.png")

# ╔═╡ f3de1ed6-4226-428a-9f17-bac02113c8ef
md"""
Overlay successful runs with runs which are bad in Ur and Np _simultaneously_. Potentially better to remove this smaller set and easier to justify too? for further analysis!
"""

# ╔═╡ cd5563d7-6dc1-4aec-940e-940a53b630d1
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
	plot!(sort(X_design.FactorB0), 9e5 ./ (sort(X_design.FactorB0)), line=(:cyan, 2), label="FactorB0 x PoyntingFluxPerBSi= 9e5")
	plot!(ylims=(0.3e6, 1.1e6))
	plot!(guidefontsize=26)
	plot!(tickfontsize=21)
	plot!(framestyle=:box)
	plot!(left_margin=5mm)
	plot!(bottom_margin=5mm)
	plot!(right_margin=8mm)
	plot!(yticks=([4e5, 6e5, 8e5, 1e6], ["4.0e5", "6.0e5", "8.0e5", "1.0e6"]))
	plot!(size=(800, 600))
end

# ╔═╡ d5d8f39a-a4c7-4be5-89b7-606faee68441
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
end

# ╔═╡ c2783ea6-59bb-4820-b5ec-ef1737b75f55
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

end

# ╔═╡ 7d8fd7ec-de78-4286-a140-e2e3f7e927d5
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
				
end

# ╔═╡ 68bc3169-9fba-46d8-b712-5561ab3d38f5
begin
			# savefig(pScatterUncolored, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/brpf_cr2152.png")
			# savefig(LperpStoch, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/lpse_cr2152.png")
			# savefig(chromoLperp, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/nclp_cr2152.png")
			# savefig(LperpRMin, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/lprm_cr2152.png")
	
end

# ╔═╡ 696771be-5bd1-461d-a66e-7180c8e4d883
md"""
Make similar uncolored scatterplots for the remaining!
"""

# ╔═╡ a4f4bd49-7abf-4fee-addd-f3e46cb0c969
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

# ╔═╡ 1fb93f2f-0bd3-4bcf-8e12-791240de0a8e
pParamsUncolored[14]

# ╔═╡ 9509f3ae-eea1-414f-b01e-423bf55b281f


# ╔═╡ 4f0d6b2c-1ddb-4eed-ac0f-47b215d3cfc5
md"""
Save all the above uncategorized scatterplots.
"""

# ╔═╡ 76e7ec02-f2d8-4e41-a7d2-3db6a9f7a3f1
# [savefig(pParamsUncolored[i], 
# 	"/Users/ajivani/Downloads/Solar_Model_UQ_big/figures/doe/all_param_scatterplots/scatterplot_" * @sprintf("%02d.png", i)) for i in 1:10]
# savefig(pScatterUncolored, "/Users/ajivani/Downloads/Solar_Model_UQ_big/figures/doe/all_param_scatterplots/scatterplot_02.png")

# ╔═╡ ec316bdc-0a3c-4cd2-832a-0151fc286f7c
# plot(pParamsUncolored..., layout=(2, 5), size=(1400, 800))

# ╔═╡ 6f92ad8f-285d-4405-a255-30fd84446f0d
savefig(pParamsUncolored[14], "/Users/ajivani/Downloads/Solar_Model_UQ_big/figures/doe/all_param_scatterplots/scatterplot_14.png")

# ╔═╡ e1efe03f-fac8-4bcd-8ae6-9e83b54ab449
length(pParamsUncolored)

# ╔═╡ 125cfdbe-09e0-4c20-84c3-117e61bec1f3
md"""
Make a colored scatterplot as well with appropriate legend
"""

# ╔═╡ de548dee-eead-4c00-97a5-8c5679b0367a
# savefig(pScatterGroupedSimFail, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/cr2152_colored_final_hires.png")

# ╔═╡ e101279e-5b6c-4ca6-8f52-720599cdc792
md"""
Now finally the revised bootstrapping plots. Do we wish to show something more meaningful over here in place of 2 standard deviations??
"""

# ╔═╡ 8e5a8e4d-1bec-4c63-9e96-77593357d063
md"""
First call the function to bootstrap GSA, we will go from 20 to 160 samples? We will not regularize since deciding how much to regularize is not a trivial question and we want a quick analysis of general trend wrt sample size.
"""

# ╔═╡ bf157b74-14c4-49f4-a041-bc963dbe5370
# begin
# 	UrBootstrapFinal = bootstrapGSA(XTrainFinal, YTrainUr; regularize=false, nStart=20, nEnd=160, nStep=20)
# 	NpBootstrapFinal = bootstrapGSA(XTrainFinal, YTrainNp; regularize=false, nStart=20, nEnd=160, nStep=20)
# end

# ╔═╡ 8ea02c1a-f22e-4034-89a6-b41a2b19bd86
md"""
Save bootstrap data to JLD files
"""

# ╔═╡ 190a1cd3-bf39-43db-b3ba-117fff572cce
# begin
# 	save("/Users/ajivani/Desktop/Research/SWQUPaper/Ur2152BootstrapFinal.jld", "UrBootstrap", UrBootstrapFinal)
# 	save("/Users/ajivani/Desktop/Research/SWQUPaper/Np2152BootstrapFinal.jld", "NpBootstrap", NpBootstrapFinal)
# end

# ╔═╡ 4ab9914d-2028-46a0-823d-03e95fb1c1d5
begin
	UrBootstrapFinal = load("/Users/ajivani/Desktop/Research/SWQUPaper/Ur2152BootstrapFinal.jld", "UrBootstrap")
	avgBootstrapUrFinal = mean(UrBootstrapFinal; dims=2)[:, 1, :, :]
	avgBootstrapRepsUrFinal = mean(avgBootstrapUrFinal; dims=2)[:, 1, :]
	stdBootstrapRepsUrFinal = std(avgBootstrapUrFinal; dims=2)[:, 1, :]
end

# ╔═╡ 03a6436a-178f-4676-ab15-dc46e5945b43
begin
	NpBootstrapFinal = load("/Users/ajivani/Desktop/Research/SWQUPaper/Np2152BootstrapFinal.jld", "NpBootstrap")
	avgBootstrapNpFinal = mean(NpBootstrapFinal; dims=2)[:, 1, :, :]
	avgBootstrapRepsNpFinal = mean(avgBootstrapNpFinal; dims=2)[:, 1, :]
	stdBootstrapRepsNpFinal = std(avgBootstrapNpFinal; dims=2)[:, 1, :]
end

# ╔═╡ 4747b516-453c-4c38-be36-12697d23ecdb
md"""
Repeat process for Ur
"""

# ╔═╡ fbd96575-fb29-4b66-8e49-014222fefd9c
md"""
SIMIDToPlot = $(@bind EnsemblePlotID MultiSelect([string.(successBothCriteria[i]) => successBothCriteria[i] for i in 1:length(successBothCriteria)]))
"""

# ╔═╡ e3a45f13-24e1-4048-8305-6ffc01f9af5f
begin
	# savefig(pUrSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/UrSims_CR2152_final_noobs.png")
	# savefig(pNpSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/NpSims_CR2152_final_noobs.png")
	# savefig(pBSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/BSims_CR2152_final_noobs.png")
	# savefig(pTSimObsF, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/TSims_CR2152_final_noobs.png")
end

# ╔═╡ dcfa8083-8d0f-40b5-93f8-a59c12e45cb9
md"""
Repeat the estimation procedure for the log of density!
"""

# ╔═╡ e2cfadc1-157e-40da-b9be-82fc8f7d5333
begin
	# XTrainFinal = Matrix(paramsBgScaled[successBothCriteria, :])
	# YTrainUr = Array{Float64, 2}(UrSim[:, successBothCriteria]')
	YTrainNpLog = Array{Float64, 2}(log.(NpSim[:, successBothCriteria])')
end

# ╔═╡ 53c967ed-8a04-4933-8eaf-d4b1fad37530
plot(YTrainNpLog', label="")

# ╔═╡ 31d6c661-7474-4a60-93fd-84a2465bf0f1
# build coefficient matrix!
# ATrainFinal = buildCoefficientMatrix(XTrainFinal; pceDegree=2)

# ╔═╡ 09e63a6b-74ec-405e-bc49-3811f140533e


# ╔═╡ 8ecbdf26-932c-450c-ba2c-df1cc86d0962
md"""
Get PC coefficients for log of Np
"""

# ╔═╡ ec0d2cdb-aafc-4154-9506-e4fa6555a2c0
# betaUrFinal = solveRegPCE(ATrainFinal, YTrainUr; λ=lambdaUrFinal)

# ╔═╡ 4ea98012-2249-4780-bc64-22622392df79
size(yPredNpFinal)

# ╔═╡ a91ba0f1-35cc-44eb-81ba-a4b016e8a18e


# ╔═╡ fc2ed2d7-7751-4e62-a61f-8552494db945
md"""
Get sensitivity indices
"""

# ╔═╡ ca9dd14c-79e8-4623-a343-11933c7b2108


# ╔═╡ cf015ad5-e812-4261-9e97-2536ab1c6742
# lambdaUrFinal = 0.4

# ╔═╡ 57b23606-218b-425e-987b-e55754484eef
lambdaNpLogFinal = 2

# ╔═╡ 2cba3a7e-09fc-4c79-b70f-423c37ad1c20
betaNpLogFinal = solveRegPCE(ATrainFinal, YTrainNpLog; λ=lambdaNpLogFinal)

# ╔═╡ 8454147b-1ca3-4c20-8f8f-3eb0f9a63205
yPredNpLogFinal = betaNpLogFinal[1, :] .+ Matrix((ATestFinalFilteredC * betaNpLogFinal[2:end, :])')

# ╔═╡ ee5ab1fa-586f-4e1a-a650-70c1307eac06
yPredNpTransformed = exp.(yPredNpLogFinal)

# ╔═╡ e4f1f96d-c565-4c0f-b7f5-4791f7a2f19f
begin
	meanEmpiricalNpLogFinal = mean(yPredNpTransformed; dims=2)
	stdEmpiricalNpLogFinal  = std(yPredNpTransformed; dims=2)[:]
end

# ╔═╡ 1ddd2e0b-907e-4163-af90-5b121ce67617
std(yPredNpTransformed; dims=2)

# ╔═╡ 9252e165-3059-496f-b9b1-c85f2cdacb12
plot(yPredNpTransformed, label="")

# ╔═╡ 69c5d767-43de-4dc9-adfb-780b9969fdb1
minimum(yPredNpTransformed)

# ╔═╡ ee2001dd-09a7-4d12-8f8e-a14482990eef
maximum(yPredNpTransformed)

# ╔═╡ d36de2f1-ba3f-4591-9843-f8a3caa3c010
begin
	plotUncertainty(yPredNpTransformed, meanEmpiricalNpLogFinal, stdEmpiricalNpLogFinal, NpObs, ylabel="Nₚ [cm⁻³]", ylims=(-20, 120), times, nSTD=2, trimIndices=(1, 577))
	plot!(guidefontsize=20)
	plot!(tickfontsize=15)
	plot!(legend=:topleft)
	plot!(left_margin=2mm)
	plot!(bottom_margin=3mm)	
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/cr2152_uncertainty_boxplots_nplog.png")
end

# ╔═╡ 2f1930ee-cdb2-4791-83e9-38bb96fa71a5
begin
	# gsaUrFinal = gsa(XTrainFinal, YTrainUr; regularize=false, pceDegree=2, lambda=lambdaUrFinal)
	gsaNpLogFinal = gsa(XTrainFinal, YTrainNpLog; regularize=true, pceDegree=2, lambda=lambdaNpLogFinal)
end

# ╔═╡ 0b09a909-c6f4-4f7c-b2ba-8e595918002e
gsaMainNpLogFinal = processMainEffects(gsaNpLogFinal)

# ╔═╡ 565ce9a2-1fa3-4799-b4c6-1b5ac4473681


# ╔═╡ 047d2a25-abb3-4e97-bddf-c13c7c2aefcc


# ╔═╡ 4eb9b4d5-4e09-44cb-acc7-b43afa41554b
md"""
### Scratchwork for uncertainty plots
"""

# ╔═╡ 19c33fed-b4bb-46eb-a5d3-38b26870277c
violin(repeat([1,2,3],outer=100),randn(MersenneTwister(0), 300), side=:right, linewidth=0, fillalpha=0.7)

# ╔═╡ 38da0325-7075-4277-bba8-f7fb1420f803


# ╔═╡ ea0376d3-b7a1-4515-8a2d-b70f87566bc0
yPredUrFinal[151, :]

# ╔═╡ fe7c2d3a-57c2-439c-9fc7-f342bc4126cd
yPredUrFinal[181, :]

# ╔═╡ fdb91b27-01a9-4475-8393-f2ff2b70968b
yPredUrFinal[[151, 181], :]

# ╔═╡ 419a0a63-c53d-40e1-bb4e-e97d01833123
yPredUrFinal[[151, 181], :][:]

# ╔═╡ b6872b87-bf26-488e-928d-c4eb052df62a
repeat([1, 2, 3], inner=5)

# ╔═╡ 1d54de4f-832a-4f80-b8dd-8767e8cf5145
repeat(1:3, outer=5)

# ╔═╡ fc47c8b4-9703-46fb-8559-517826fa7d6f
collect(1:30:577)

# ╔═╡ 4b7a37c4-d08f-492a-aa69-0eb434444a68
boxplot(yPredUrFinal[151, :])

# ╔═╡ afb01af5-0a81-43c3-baf2-292fb0c4e3c2
	violin(repeat([1, 2], inner=400), yPredNpFinal[[211, 241], :][:]; 
		side=:right,
		label="", 
		# bar_width=120/length(densitiesToPlot), 
		# outliers=false, 
		fillcolor=:orange,
		fillalpha=0.7,
		# whisker_range=1.5
	)

# ╔═╡ 100699a0-b09a-4790-9c7c-3ff2d831908b
md"""
### Scatterplots of param space (old)
"""

# ╔═╡ 5f0ee59f-458e-48d5-bcd4-591f735e2596
successful = X_design[successfulRuns, :]

# ╔═╡ eb54ac0e-4135-4cdb-b0fe-0aff5dedbe79
failed = X_design[Not(successfulRuns), :]

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
plot!(sort(X_design.FactorB0), 9e5 ./ (sort(X_design.FactorB0)), line=(:red, 2), label="FactorB0 x PoyntingFlux = 9e5")
plot!(ylims=(0.3e6, 1.1e6))
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/scatterPlotCR2152.png")
end

# ╔═╡ bd90bd75-b762-4880-aac2-fbbdd42a5b5c
begin
# 	pScatterFPModified = scatter(successful[!, "FactorB0"], successful[!, "PoyntingFluxPerBSi"], 
# 	# zcolor=shiftWLRMSE.PTRMSE, 
# 	marker=(:green, :circle, 4), 
# 	xlabel="FactorB0", 
# 	ylabel="PoyntingFluxPerBSi",
# 	markerstrokewidth=0,
# 	label="Successful",
# 	dpi=350
# )
pScatterRMSE = scatter(X_design[success2KeepIDs, "FactorB0"], X_design[success2KeepIDs, "PoyntingFluxPerBSi"], 
					zcolor=rmseUr,
					marker=(:circle, 4),
					markerstrokewidth=0,
					label=""
)
# scatter!(X_design[totalExcluded, "FactorB0"], X_design[totalExcluded, "PoyntingFluxPerBSi"],
# 		 marker=(:blue, :circle, :4),
# 		# xlabel=name_x,
# 		# ylabel=name_y,
# 		markerstrokewidth=0,
# 		label="Removed")
# scatter!(failed[!, "FactorB0"], failed[!, "PoyntingFluxPerBSi"],
# 		marker=(:red, :circle, 4),
# 		# xlabel=name_x,
# 		# ylabel=name_y,
# 		markerstrokewidth=0,
# 		label="Failed")
plot!(sort(X_design.FactorB0), 9e5 ./ (sort(X_design.FactorB0)), line=(:red, 2), label="FactorB0 x PoyntingFlux = 9e5")
plot!(ylims=(0.3e6, 1.1e6))

plot(pScatterFPModified, pScatterRMSE, layout=(1, 2), size=(1000, 600))
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/doe/scatterPlotCR2152.png")
end

# ╔═╡ cac093d1-33b2-4a14-9d54-8ff6813f0929
begin
	pScatterGroupedSimFail = scatter(X_design[successBothCriteria, "FactorB0"], X_design[successBothCriteria, "PoyntingFluxPerBSi"], 
								marker=(:green, :circle, 4), 
								xlabel="FactorB0", 
								ylabel="PoyntingFluxPerBSi",
								markerstrokewidth=0,
								label="Runs used for PCE and GSA",
								dpi=300
								)
	scatter!(X_design[excludeBothCriteriaOnly, "FactorB0"], X_design[excludeBothCriteriaOnly, "PoyntingFluxPerBSi"],
		marker=(:blue, :circle, 4),
		# xlabel=name_x,
		# ylabel=name_y,
		markerstrokewidth=0,
		label="Removed from ensemble")
	scatter!(failed[!, "FactorB0"], failed[!, "PoyntingFluxPerBSi"],
			marker=(:red, :circle, 4),
			# xlabel=name_x,
			# ylabel=name_y,
			markerstrokewidth=0,
			label="Failed simulations with no 1 AU results")
	plot!(sort(X_design.FactorB0), 9e5 ./ (sort(X_design.FactorB0)), line=(:cyan, 2), label="FactorB0 x PoyntingFluxPerBSi= 9e5")
	plot!(ylims=(0.3e6, 1.1e6))
	plot!(framestyle=:box)
	plot!(grid=false)
end

# ╔═╡ 1fa64af2-1965-4748-8c79-78b62acf8060
removed = X_design[Not(runsToKeep), :]

# ╔═╡ fdd08dc8-5f22-4e54-ae7a-cb41a1183d47
# make real removed matrix based on success2KeepIDs
removed2 = X_design[totalExcluded, :]

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

# ╔═╡ 7f9e8486-4674-452c-82b1-0666b8713d33
pCI = 

# ╔═╡ bdbdd861-463a-409a-9dd0-edb1a973b7f2
totalExcluded

# ╔═╡ 1d6219bc-575b-4703-a058-ec50fe276e15
md"""
Make same plot as above but with the 4 groups of runs clearly marked instead of being lumped together as "R" in blue!
"""

# ╔═╡ cf7fbefa-e91c-4908-b2e5-75d8c28f6611
linecolors = palette(:default)

# ╔═╡ 7e3a1a49-fb0f-4484-8b49-0023a2deb4fc
begin
	pScatterFPGrouped = scatter(X_design[success2KeepIDs, "FactorB0"], X_design[success2KeepIDs, "PoyntingFluxPerBSi"], 
	# zcolor=shiftWLRMSE.PTRMSE, 
	marker=(:green, :circle, 4), 
	xlabel="FactorB0", 
	ylabel="PoyntingFluxPerBSi",
	markerstrokewidth=0,
	label="S"
)

# scatter!(X_design[totalExcluded, "FactorB0"], X_design[totalExcluded, "PoyntingFluxPerBSi"],
# 		 marker=(:blue, :circle, :4),
# 		# xlabel=name_x,
# 		# ylabel=name_y,
# 		markerstrokewidth=0,
# 		label="R")
scatter!(failed[!, "FactorB0"], failed[!, "PoyntingFluxPerBSi"],
		marker=(:red, :circle, 4),
		# xlabel=name_x,
		# ylabel=name_y,
		markerstrokewidth=0,
		label="F")

scatter!(X_design[clusters_by_eye[1], "FactorB0"], X_design[clusters_by_eye[1], "PoyntingFluxPerBSi"],
		marker=(linecolors[15], :star5, 6),
		markerstrokewidth=0,
		label="Group 1"
)

scatter!(X_design[clusters_by_eye[2], "FactorB0"], X_design[clusters_by_eye[2], "PoyntingFluxPerBSi"],
		marker=(linecolors[4], :diamond, 6),
		markerstrokewidth=0,
		label="Group 2"
)

scatter!(X_design[clusters_by_eye[3], "FactorB0"], X_design[clusters_by_eye[3], "PoyntingFluxPerBSi"],
		marker=(linecolors[5], :rtriangle, 9),
		markerstrokewidth=0,
		label="Group 3"
)

scatter!(X_design[clusters_by_eye[4], "FactorB0"], X_design[clusters_by_eye[4], "PoyntingFluxPerBSi"],
		marker=(linecolors[6], :star8, 6),
		markerstrokewidth=0,
		label="Group 4"
)

plot!(sort(X_design.FactorB0), 9e5 ./ (sort(X_design.FactorB0)), line=(:pink, 2), label="9e5 (original cutoff for new design)")
plot!(ylims=(0.3e6, 1.2e6))


end

# ╔═╡ 5d78a235-7db8-4441-8bd3-ad1ecc2808c6
@bind ParamX Select(inputNames)

# ╔═╡ 3b4b07d4-0701-40db-b056-c84dd075f4c1
@bind ParamY Select(inputNames)

# ╔═╡ 7ce99bc4-f968-4878-98e0-9fffc94cc5f8
begin
	pScatterParamXParamY = scatter(X_design[success2KeepIDs, ParamX], X_design[success2KeepIDs, ParamY], 
	# zcolor=shiftWLRMSE.PTRMSE, 
	marker=(:green, :circle, 4), 
	xlabel=ParamX, 
	ylabel=ParamY,
	markerstrokewidth=0,
	label="S"
)

scatter!(failed[!, ParamX], failed[!, ParamY],
		marker=(:red, :circle, 4),
		markerstrokewidth=0,
		label="F")

scatter!(X_design[clusters_by_eye[1], ParamX], X_design[clusters_by_eye[1], ParamY],
		marker=(linecolors[15], :star5, 6),
		markerstrokewidth=0,
		label="Group 1"
)

scatter!(X_design[clusters_by_eye[2], ParamX], X_design[clusters_by_eye[2], ParamY],
		marker=(linecolors[4], :diamond, 6),
		markerstrokewidth=0,
		label="Group 2"
)

scatter!(X_design[clusters_by_eye[3], ParamX], X_design[clusters_by_eye[3], ParamY],
		marker=(linecolors[5], :rtriangle, 9),
		markerstrokewidth=0,
		label="Group 3"
)

scatter!(X_design[clusters_by_eye[4], ParamX], X_design[clusters_by_eye[4], ParamY],
		marker=(linecolors[6], :star8, 6),
		markerstrokewidth=0,
		label="Group 4"
)


end

# ╔═╡ a17c9fc2-63f1-4707-bdb9-0aa8da50a609
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

# ╔═╡ e7e9d13b-8d82-4fca-b2fd-9b839207081e
md"""
### Bootstrapping results
"""

# ╔═╡ f6d63720-c3eb-4e90-bebc-f859c582602c
# begin
# 	using JLD
# 	UrBootstrap = bootstrapGSA(X, Y1; regularize=false, nStart=20, nEnd=140, nStep=20)
# 	NpBootstrap = bootstrapGSA(X, Y2; regularize=false, nStart=20, nEnd=140, nStep=20)
# end

# ╔═╡ 212ce0e8-ffe3-4531-9e02-d872ca12d1b8
begin
	UrBootstrap = load("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapUr2152.jld", "UrBootstrap")
	avgBootstrapUr = mean(UrBootstrap; dims=2)[:, 1, :, :]
	avgBootstrapRepsUr = mean(avgBootstrapUr; dims=2)[:, 1, :]
	stdBootstrapRepsUr = std(avgBootstrapUr; dims=2)[:, 1, :]
end

# ╔═╡ a89c649b-e12d-4668-acca-b813eaaafcca
avgBootstrapUr

# ╔═╡ c3e2ed93-8063-432b-8a9c-26ddaf4a45c5
histogram(avgBootstrapUr[6, :, 7])

# ╔═╡ da5658a7-0cd3-4927-989c-3216f7774cef
begin
	NpBootstrap = load("/Users/ajivani/Desktop/Research/SWQUPaper/bootstrapNp2152.jld", "NpBootstrap")
	avgBootstrapNp = mean(NpBootstrap; dims=2)[:, 1, :, :]
	avgBootstrapRepsNp = mean(avgBootstrapNp; dims=2)[:, 1, :]
	stdBootstrapRepsNp = std(avgBootstrapNp; dims=2)[:, 1, :]
end

# ╔═╡ a9bf4f3d-25b2-4016-bfc8-ef8500bcd3e1
stdBootstrapRepsNp

# ╔═╡ f2571662-10cf-462b-a9bc-8f2c7e7760bc
barcolors = palette(:tab10, rev=true)

# ╔═╡ f161fecb-b470-4acd-8c3b-ac963e06b9c2
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
	# savefig(pBarSummaryFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/bootstrapNew/cr2152/Np_$(sampleSize).png")
end

# ╔═╡ aa8043ae-9843-448c-bf83-4d2807bc1e68
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
	# savefig(pBarSummaryFinal, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/bootstrapNew/cr2152/Ur_$(sampleSize).png")
end

# ╔═╡ 397bad9d-e5f3-43fc-8f65-fe69fda4c31e
barcolors

# ╔═╡ 92d64706-4da7-48f7-b891-d2ed75e1ae3e
[barcolors[i] for i in 1:6]'

# ╔═╡ 23086bf0-54e0-4930-b161-5cca60e4166b
begin
barColored = bar(
	# (1:6)',
	reshape(inputNames, 1, 6),
	avgBootstrapRepsNp[:, 1]',
	yerr=stdBootstrapRepsNp[:, 1]',
	xrot=20,
	ylims=(0, 1),
	bar_width=1.6,
	label="",
	ylabel="Main effects",
	title="N = 20",
	framestyle=:box,
	dpi=400,
	color=[barcolors[i] for i in 1:6]',
	# color=reshape([linecolors[1], linecolors[2], linecolors[3], linecolors[4], linecolors[5], linecolors[6]], 1, 6),
	linewidth=2,
	markerstrokewidth=2,
	grid=true
	)

barPlain = bar(
	inputNames,
	avgBootstrapRepsNp[:, 1],
	yerr=stdBootstrapRepsNp[:, 1],
	xrot=20,
	ylims=(0, 1),
	bar_width=0.8,
	label="",
	ylabel="Main effects",
	title="N = 20",
	framestyle=:box,
	dpi=400,
	linewidth=2,
	markerstrokewidth=2,
	grid=false
)
plot(barColored, barPlain, layout=(1, 2), size=(1000, 600))
end

# ╔═╡ 4dc9c13c-c371-46a5-bb60-dffa0eac9920
default(legendfontsize=10)

# ╔═╡ 46780314-a7dc-4073-a9d6-30fafb31a7f6
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
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/bootstrap_cr2152_final_line_Ur.png")
end

# ╔═╡ 2d52ca70-1ee9-4ac9-b7cc-630c12f262fd
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
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/bootstrap_cr2152_final_line_Np.png")
end

# ╔═╡ dcbc72be-820a-4b2b-be72-32aef3e92f52
reshape(inputNames, 1, 6)

# ╔═╡ f2edb22d-acfa-411d-8259-21cf13f4ce4f
# pUrSimObs

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

# ╔═╡ d290eece-7dbe-4e1a-8966-b611b781b6b7
plotMainEffects2(mainEffectsRegUr, times, inputNames)

# ╔═╡ 48a62f1c-2b91-44c0-9316-fae67c91835c
plotMainEffects2(mainEffectsRegNp, times, inputNames, ylabel="Np")

# ╔═╡ 91d7393d-f8fb-49a1-ade0-6a4d3650ff00
begin
	pMainUr = plotMainEffects2(mainEffectsUr, times, inputNames)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/new/ME2152Ur.png")
end

# ╔═╡ 12df4a54-1450-4bff-9509-298aa1604664
begin
	pMainNp = plotMainEffects2(mainEffectsNp, times, inputNames, ylabel="Np")
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/new/ME2152Np.png")
end

# ╔═╡ d196ab6f-5c67-4efb-a44d-02fb80fcd970
begin
	pUrMain = plotMainEffects2(mainEffectsUr, times, inputNames, ylabel="Ur", showLabels=true)
	plot!(parse(Int, timeIdx) * ones(50), range(0, 1, length=50), line=(:red, 2), label="")
	pNpMain = plotMainEffects2(mainEffectsNp, times, inputNames, ylabel="Np")
	plot!(parse(Int, timeIdx) * ones(50), range(0, 1, length=50), line=(:red, 2), label="")
	plot(pUrMain, pNpMain, layout=(1, 2), size=(1400, 600))
end

# ╔═╡ d3479ed1-25e9-4702-a006-2646d7f1475e
begin
	pMainUrFinal = plotMainEffects2(gsaMainUrFinal, times, inputNames; title = "Sensitivity for Uᵣ", dpi=300)
	plot!(grid=false)
	plot!(xtickfontsize=8)
	plot!(ytickfontsize=10)
	plot!(guidefontsize=13)
end

# ╔═╡ 5c440b29-0a18-4be6-b2cc-ac369e66a269
begin
	pMainNpFinal = plotMainEffects2(gsaMainNpFinal, times, inputNames; title="Sensitivity for Nₚ", dpi=300)
	plot!(grid=false)
	plot!(xtickfontsize=8)
	plot!(ytickfontsize=10)
	plot!(guidefontsize=13)
end

# ╔═╡ 8b7ebbc2-f67b-4580-81d7-bd29329ff679
begin
	pMainNpLogFinal = plotMainEffects2(gsaMainNpLogFinal, times, inputNames; title="Sensitivity for log(Nₚ)", dpi=300)
		plot!(grid=false)
	plot!(xtickfontsize=8)
	plot!(ytickfontsize=10)
	plot!(guidefontsize=13)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/me_Np2152Log.png")
end

# ╔═╡ d6e964d1-c6bc-4659-978f-ce890fd6401e
collect(-0.5:0.5:5.5)

# ╔═╡ c5d8462a-5526-4e30-804d-62fa38064f39
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

# ╔═╡ 21b9bd18-4e4a-401a-b7a8-f361d73526b6
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

# ╔═╡ 808302e7-6664-484e-80d9-b9dab1b892a3
plotInteractionEffects2(gsaRegUr, times, inputNames)

# ╔═╡ 17a77483-c1e9-460d-9200-a03a56485af5
plotInteractionEffects2(gsaRegNp, times, inputNames)

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
	# savefig("/Users/ajivani/Downloads/IE2152.png")
end

# ╔═╡ 35a5c725-b392-4bf3-b6a0-bf81fa4883b4
pUrIntMean

# ╔═╡ 9e0d741f-b59c-4613-b112-db485bb81a27
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

# ╔═╡ 8d28f254-ab2a-4dc8-bef9-15505504cdee
begin
	pNpLogIntMeanFinal = plotInteractionEffects2(gsaNpLogFinal, times, inputNames, dpi=300)
	plot!(tickfontsize=12)
	plot!(bottom_margin=9mm)
	plot!(right_margin=3mm)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/gsa/ie_Np2152Log.png")
end

# ╔═╡ c1821487-7509-4b20-bcf1-3b81da2fcebb
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

# ╔═╡ ba3bbb87-75e4-4c69-ab60-bc78d86e7045
begin
	pIntMeanAll = plotInteractionSummary(interactionsUr, interactionsNp, times, inputNames)
	# savefig("/Users/ajivani/Downloads/pIntMeanCR2152.png")
end

# ╔═╡ c36bd405-4990-411c-8ec4-4e2a57f22dc8
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

# ╔═╡ 48f6ad03-287c-4413-beb5-dfa2e2f101df
begin
	pUrSimObs = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsUr...)
	pNpSimObs = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsNp...)
	pBSimObs  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, EachSimID), plotArgsB...)
	plot(pUrSimObs, pNpSimObs, pBSimObs, layout=(1, 3), xlabel="", size=(1500, 600))
	plot!(xrot=10)
	plot!(title="All Successful")
	# plot!(xrot=25)
end

# ╔═╡ 4e56b3d7-9270-4df8-8c34-82d9646fca17
# make plots of only runs that are successful and satisfy the constraints
begin
	pUrSimObs2 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsUr...)
	pNpSimObs2 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsNp..., ylims=(0, 100))
	pBSimObs2  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsB...)
	# plot(pUrSimObs2, pNpSimObs2, pBSimObs2, layout=(1, 3), xlabel="", size=(1500, 800))
	plot(pUrSimObs2, pNpSimObs2, pBSimObs2, layout=(1, 3), xlabel="", size=(1500, 550))
	plot!(xrot=10)
	plot!(title="All Successful")
	# plot!(xrot=25)
end

# ╔═╡ dab57726-6a08-42eb-8920-62a582e2128f
# pBSimObs2L = plot(pBSimObs2, legend=false, size=(800, 600))
pBSimObs2L = plot(pBSimObs2)

# ╔═╡ f8d94155-b7a5-44ec-acd1-652ca1b97450
pUrSimObs2L = plot(pUrSimObs2)

# ╔═╡ 38d1d913-fe8d-4623-a0ef-854b6f5b141d
pNpSimObs2

# ╔═╡ 349ade04-2379-45be-b207-f0991c891e67
begin
	pTSimObs2 = plotSimObs2(TSim, TObs, times, collect(1:200); simIdx=parse.(Int, ToKeepSims), plotArgsT..., ylims=(0, 5e5))
	# pTSimObs2L = plot(pTSimObs2, legend=false)
	pTSimObs2L = plot(pTSimObs2)
end

# ╔═╡ 47ad7549-e711-42a4-a29b-493515363355
begin
	pUr = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, ExcludedSims), plotArgsUr..., ylims=(200, 1100))
	pNp = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, ExcludedSims), plotArgsNp..., ylims=(0, 100))
	pB  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, ExcludedSims), plotArgsB...)
	plot(pUr, pNp, pB, layout=(1, 3), xlabel="", size=(1500, 450))
	plot!(xrot=10)
	plot!(title="Runs Discarded")
	# plot!(xrot=25)
end

# ╔═╡ d706df04-16e1-4a5a-ba33-451ecc7d09ea
pUr

# ╔═╡ 00183765-57b0-479f-b1fa-ffca516b75c2
pNp

# ╔═╡ 1ae0952c-129d-4dd1-8a6c-d0703d273137
savefig(pNp, "/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/filteredCR2152Np.png")

# ╔═╡ 21b83965-d2ba-4b1c-9997-4a15119494d1
begin
	pUrClust1 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=clusters_by_eye[1], plotArgsUr..., ylims=(200, 1100))
	pNpClust1 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=clusters_by_eye[1], plotArgsNp..., ylims=(0, 180))
	pBClust1  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=clusters_by_eye[1], plotArgsB...)
	plot(pUrClust1, pNpClust1, pBClust1, layout=(1, 3), xlabel="", size=(1500, 450))
	plot!(xrot=10)
	plot!(title="Runs Discarded group 1")
	# plot!(xrot=25)
end

# ╔═╡ a0c7b30b-3375-49e1-ace1-179aa791185f
begin
	pUrClust2 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=clusters_by_eye[2], plotArgsUr..., ylims=(200, 1100))
	pNpClust2 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=clusters_by_eye[2], plotArgsNp..., ylims=(0, 140))
	pBClust2  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=clusters_by_eye[2], plotArgsB...)
	plot(pUrClust2, pNpClust2, pBClust2, layout=(1, 3), xlabel="", size=(1500, 450))
	plot!(xrot=10)
	plot!(title="Runs Discarded group 2")
	# plot!(xrot=25)
end

# ╔═╡ 75140e3a-a77c-461d-b844-05fb20d695dc
begin
	pUrClust3 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=clusters_by_eye[3], plotArgsUr..., ylims=(200, 1100))
	pNpClust3 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=clusters_by_eye[3], plotArgsNp..., ylims=(0, 140))
	pBClust3  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=clusters_by_eye[3], plotArgsB...)
	plot(pUrClust3, pNpClust3, pBClust3, layout=(1, 3), xlabel="", size=(1500, 450))
	plot!(xrot=10)
	plot!(title="Runs Discarded group 3")
	# plot!(xrot=25)
end

# ╔═╡ 1ff234d4-49a8-42e3-9b62-18f27a90103d
begin
	pUrClust4 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=clusters_by_eye[4], plotArgsUr..., ylims=(200, 5000))
	pNpClust4 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=clusters_by_eye[4], plotArgsNp..., ylims=(0, 22000))
	pBClust4  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=clusters_by_eye[4], plotArgsB..., ylims=(0, 4000))
	plot(pUrClust4, pNpClust4, pBClust4, layout=(1, 3), xlabel="", size=(1500, 450))
	plot!(xrot=10)
	plot!(title="Runs Discarded group 4")
	# plot!(xrot=25)
end

# ╔═╡ c6026c31-4d90-4220-8417-c06f156f40fe
begin
	pUrClust5 = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=excludeBothCriteriaOnly, plotArgsUr..., ylims=(200, 1100))
	pNpClust5 = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=excludeBothCriteriaOnly, plotArgsNp..., ylims=(0, 140))
	pBClust5  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=excludeBothCriteriaOnly, plotArgsB...)
	plot(pUrClust5, pNpClust5, pBClust5, layout=(1, 3), xlabel="", size=(1500, 450))
	plot!(xrot=10)
	plot!(title="Runs bad in Ur, Np simultaneously")
	# plot!(xrot=25)
end

# ╔═╡ 1c465cf3-9d33-4ca8-ac24-d7d2367ce47e
begin
	# make plots of the runs that are successful and satisfy the constraints
		pUrSimObsF = plotSimObs2(UrSim, UrObs, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsUr..., ylims=(100, 800))
		plot!(guidefontsize=16)
		plot!(left_margin=5mm)
		plot!(bottom_margin=3mm)
		plot!(ytickfontsize=10)
		
end

# ╔═╡ b6ea00b1-3ef7-4b2c-b277-e8bfeb08e4e4
begin
	pNpSimObsF = plotSimObs2(NpSim, NpObs, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsNp..., ylims=(0, 140))
		plot!(guidefontsize=16)
		plot!(left_margin=5mm)
		plot!(bottom_margin=3mm)
		plot!(ytickfontsize=10)
end

# ╔═╡ 7e6d8183-7caa-4535-8ac2-a6825d64ded4
begin
	pBSimObsF  = plotSimObs2(BSim, BObs, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsB...)
		plot!(guidefontsize=16)
		plot!(left_margin=5mm)
		plot!(bottom_margin=3mm)
		plot!(ytickfontsize=10)
end

# ╔═╡ eeafa2c0-924c-483a-ba0b-e274a9e54d2a
begin
	pTSimObsF = plotSimObs2(TSim, TObs, times, collect(1:200); simIdx=parse.(Int, EnsemblePlotID), plotArgsT..., ylims=(0, 5e5))
	plot!(yticks=(0:1e5:5e5, [0; [@sprintf("%de5", i) for i in 1:5]][:]))
		plot!(guidefontsize=16)
	plot!(left_margin=5mm)
	plot!(bottom_margin=3mm)
	plot!(ytickfontsize=10)
end

# ╔═╡ 910a7b75-18cb-46ee-aebf-afdf70402747
begin
	pNpSimObsLogPred = plotSimObs2(yPredNpTransformed, NpObs, times, collect(1:200); simIdx=collect(1:400), plotArgsNp..., ylims=(0, 190))
			plot!(guidefontsize=16)
	plot!(left_margin=5mm)
	plot!(bottom_margin=3mm)
	plot!(ytickfontsize=11)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/Np2152LogPredictions.png")
end

# ╔═╡ db0dcac9-b965-41d8-aa5b-e092be22e5cd
begin
	pNpSimObsOrigPred = plotSimObs2(yPredNpFinal, NpObs, times, collect(1:200); simIdx=collect(1:400), plotArgsNp..., ylims=(-30, 100))
	plot!(guidefontsize=16)
	plot!(left_margin=5mm)
	plot!(bottom_margin=3mm)
	plot!(ytickfontsize=11)
	# savefig("/Users/ajivani/Desktop/Research/SWQUPaper/figures/uq/Np2152OrigPredictions.png")
end

# ╔═╡ 354fcc56-7230-48f8-b1d4-b3cf606e495f
begin
	 # need to fix this properly!!
	pPredNp = plot(yPredNp[:, parse.(Int, selectNp)], 
				   label=" ", dpi=500)
	plot!(yPredNp[:, highlightNp], line=(:blue, 2.5), label= " ")
	plot!(legend=false)
	obsTimeTicks = range(times[1], times[end], step=Hour(84))
    xticks  = findall(in(obsTimeTicks), times)
    xticklabels = Dates.format.(obsTimeTicks, "dd-mm")
	plot!(xticks=(xticks, xticklabels))
	plot!(ylabel="Np")
	plot!(ylims=(-30, 60))
	plot!(title="Np pred without regularization")
end

# ╔═╡ bdc0a9e8-278a-4148-a629-b0e96228dd8b
begin
	# need to fix this properly!!
	pPredNpReg = plot(yPredNpReg[:, parse.(Int, selectNp)], 
					label=" ", 
					dpi=500,
					)
	plot!(yPredNpReg[:, highlightNp], line=(:blue, 2.5), label= " ")
	plot!(legend=false)
	plot!(xticks=(xticks, xticklabels))
	plot!(ylabel="Np")
	plot!(ylims=(-30, 60))
	plot!(title="Np pred with regularization")
end

# ╔═╡ 80c1d879-ef50-476b-ad14-6c562cebf27b
plot(pPredNpReg, pPredNp, layout=(1, 2), size=(800, 400))

# ╔═╡ Cell order:
# ╠═543596ec-a6e5-4779-a2a9-fea1ceb7a700
# ╠═933ae98e-d0eb-11ec-1ba6-2fc31d8c1510
# ╟─83350690-3b47-4af7-aaed-474793c23219
# ╟─6765dcad-b067-47de-98f4-d1eba31be765
# ╠═5ec433c9-0f37-4584-aace-7c1bec6fbf05
# ╠═003792f0-b399-4eba-8dd2-2da32b587219
# ╠═92b0f246-1b0f-4ce7-94a4-ebf54e95bf05
# ╠═46168df1-54af-4547-99c8-06b42a4ac864
# ╠═09e9a23f-7c39-4ce4-9f57-d1c3b71dd07c
# ╠═dfbaccaf-66af-43ea-88d8-a6e9764b146f
# ╠═18fb7539-a8aa-42b8-a78c-ece38b3b6174
# ╠═5ab604d5-584c-4b25-9e31-39d6ae13749a
# ╟─dde2906d-a892-48eb-abdf-836d2e555d22
# ╠═630fcdb2-ef98-4ae8-ad15-3ebfe37c4e00
# ╠═332d1132-9de4-4908-8125-c0f1cb7d4277
# ╠═a7d9bc78-04bf-4404-83bc-db10c92e1cce
# ╠═21939cfe-d0b3-4ecb-9fd9-e6e83827456f
# ╠═f85afd7c-c127-4444-b407-1913c0b33cf4
# ╠═bf4c95d9-13c3-45e6-8024-ae99acd589a3
# ╠═1d2a0cc4-6c09-4c3c-b13b-c5f2cc3e9455
# ╠═444f5b42-fb30-47bc-9634-a69cfe13dcb2
# ╠═5c144708-023e-460a-8a1a-431a4ad920a6
# ╠═1838ae27-128c-4bcf-9251-45dc4f79a5c7
# ╟─c18f5f64-72b9-4384-b1e6-858cfea0dd34
# ╠═48f6ad03-287c-4413-beb5-dfa2e2f101df
# ╠═804fe8bf-8106-4885-8b65-72dab17539d1
# ╠═bf379789-7caa-4231-b5c2-b1f536e733ab
# ╠═19fbe0ad-5541-4711-bde7-f96f4a07e3ab
# ╠═ee388a1e-4068-494b-a097-6e1bdff74baf
# ╠═4e56b3d7-9270-4df8-8c34-82d9646fca17
# ╠═349ade04-2379-45be-b207-f0991c891e67
# ╠═dab57726-6a08-42eb-8920-62a582e2128f
# ╠═f8d94155-b7a5-44ec-acd1-652ca1b97450
# ╠═38d1d913-fe8d-4623-a0ef-854b6f5b141d
# ╠═efc9ad22-b004-42c2-8adb-115024c42356
# ╠═5e2d1470-c487-46ed-b08d-af4a265e977d
# ╟─88fd5d74-437d-4ca9-a89f-95aa1dff0164
# ╠═d6733c06-c6da-470e-bdba-6621816fc644
# ╠═bdcfb800-c97c-4927-b2e3-e47bbe8def30
# ╠═4a6af1de-b5c4-4683-8627-d5f7f5953247
# ╠═9668f1bf-00a3-4396-82a1-bd8caca8c609
# ╟─47ad7549-e711-42a4-a29b-493515363355
# ╠═e86fee65-a9ad-42b1-819c-1a965d4d3d8a
# ╠═4e2b9048-08f9-4f95-a22a-540b553ec885
# ╟─bd90bd75-b762-4880-aac2-fbbdd42a5b5c
# ╠═fe94fe6e-6c01-40a5-aaeb-e16865f127f6
# ╟─3928276c-7518-421e-ab2b-259e3137917b
# ╟─21b83965-d2ba-4b1c-9997-4a15119494d1
# ╟─a0c7b30b-3375-49e1-ace1-179aa791185f
# ╠═75140e3a-a77c-461d-b844-05fb20d695dc
# ╟─1ff234d4-49a8-42e3-9b62-18f27a90103d
# ╟─22f03ffa-14db-45f9-b48a-530852f8de50
# ╠═c6026c31-4d90-4220-8417-c06f156f40fe
# ╠═7e3a1a49-fb0f-4484-8b49-0023a2deb4fc
# ╠═d706df04-16e1-4a5a-ba33-451ecc7d09ea
# ╠═ea27ad1a-0ad1-4500-a369-598beef3bd75
# ╠═00183765-57b0-479f-b1fa-ffca516b75c2
# ╠═1ae0952c-129d-4dd1-8a6c-d0703d273137
# ╠═b33ccfaf-31b4-4264-ab0f-99c0002610a5
# ╠═8e96c014-f34b-48d2-8c85-a40610a8725b
# ╠═5bd0e50a-6cac-471d-b29c-ab966777028b
# ╠═dc90bbc7-c265-4850-9f13-71d9705d45be
# ╟─e9b604dd-72ec-49e1-9e28-087882252164
# ╠═5a628c9d-7f2e-433a-bed1-b06d6ab7a9f6
# ╠═3814a593-8cfd-4dcb-a8f5-2320c29b3f6f
# ╠═f6aab539-3fe6-4493-8b71-7e10ce7d77c9
# ╠═122b28d6-52a2-4323-9724-fc0e4d33d591
# ╠═00241acf-85d3-4a6b-b211-96500d1d4dbb
# ╠═cf4d6e5b-a087-4769-8f27-8e3bc1ef241e
# ╠═f8c9cd60-b7b2-44fc-8877-a6956ed90aed
# ╠═33bb4cf8-dbc5-44d0-92ba-e7ce463984a7
# ╠═f2a3e375-1f96-4f1e-b8d7-4069c61d4afb
# ╠═a0a9d522-81d2-4e23-b6fa-2616636a5af8
# ╠═fb7a2484-c2d5-4b4f-bab5-13c37643cc5c
# ╠═58c4cf32-b6d2-4d34-8a82-d77083399268
# ╠═17a9bf78-9dc8-4bf1-aca0-5baf125354ff
# ╠═1b433f43-9b84-41b8-9ca2-10539b403258
# ╠═60f018c3-6142-4b39-ad7c-bed05d656afa
# ╠═d290eece-7dbe-4e1a-8966-b611b781b6b7
# ╠═48a62f1c-2b91-44c0-9316-fae67c91835c
# ╠═808302e7-6664-484e-80d9-b9dab1b892a3
# ╠═17a77483-c1e9-460d-9200-a03a56485af5
# ╠═3414a1d0-f9c1-474d-abec-dcefc143ea17
# ╠═610e5d6a-3184-4e00-ab47-85aa1e8979c8
# ╠═ba8c0fc2-9e23-49d1-8af9-2ff8321cdf5f
# ╠═48998320-efca-4032-892a-7ac3d4d48a65
# ╠═7828d7a1-8f9e-4625-9656-0f00d881c900
# ╠═04ff14d0-d714-4700-b03c-017d4fd4f759
# ╟─602c78ae-8198-4661-9042-050dea15a173
# ╠═78eeb3d4-0528-4253-802f-d164e47e759e
# ╠═ee362fc8-1c74-4561-b1d8-db94d0648e96
# ╠═037787ec-9a84-4483-87c5-5a8a44c1287e
# ╠═bbdcc6ba-e6ae-470b-8b51-9ebbaa8b2a5f
# ╠═7163eb32-198a-4589-94fc-5ad4a040bcb8
# ╠═80a1ab37-2b49-41cf-8397-7ddce37356b1
# ╠═46936905-0c76-4d6e-8e56-ed00a0abc87f
# ╟─904c8009-7574-4786-9110-4d81eeae3078
# ╠═caa03923-fb76-4fbb-97fa-8180838df025
# ╠═16f9b679-e8c5-4425-ab3e-ef8afd36f7f5
# ╟─622e3e50-ad66-4c93-8858-90cdccafb046
# ╠═6817d63a-f131-4b1f-bdda-78acae8129e3
# ╠═2dcd078b-e3ed-41da-ae8f-167e12f01f56
# ╠═8c7f863e-11a3-48f3-9f05-25c5a8be5fc8
# ╠═49f2ce13-769e-464c-8deb-68caec732c01
# ╠═74c1f916-6460-4f6c-ba2a-cfbcc5b9a274
# ╠═dd0fc3fa-b1b0-40fe-b029-4cc5c8e27f14
# ╠═1c6bdaea-ffbe-4cea-a417-c871a52b49df
# ╠═9be19580-76b6-45c2-a310-57a097568a9f
# ╠═0b4c8486-d690-4d92-b381-fcb7803a774c
# ╠═6d1ddac9-6f56-410d-a555-f1a44d42ff7c
# ╠═f5ec311a-827b-4c6a-b00c-b14d88d58dfa
# ╠═e3922291-a186-44ef-8d31-d10e8c83a51e
# ╠═41ffe6bf-e8be-4ed7-a7e5-83c28e58405c
# ╠═639559f8-874c-4e40-ba48-9269af6d018d
# ╠═82afb408-6202-4431-b6f2-fc24ef9efe72
# ╠═88b2538a-db0f-445c-a633-3e6f1cf2458b
# ╠═544c74f8-e2ad-4cae-80d0-fbccc91245a8
# ╠═f1894ca0-2dc2-425b-b0b2-0a792576a4e9
# ╠═bdf41290-1f0b-4d6d-82ab-13b13f90e798
# ╠═7fcd9c33-b383-4cdb-846b-3bfd502e8f32
# ╠═63e0448d-d15d-4534-9419-f97299fbdea0
# ╠═9bfcc241-e866-4413-8ea1-5996cfb8a8cd
# ╠═416c1a7b-c626-4e0c-b72a-8434d297a403
# ╠═ed116fd1-324f-49a2-b78a-5922be061ae8
# ╠═80c1d879-ef50-476b-ad14-6c562cebf27b
# ╠═58cee74a-e123-4e10-8196-42903bb41127
# ╠═bcccb27a-5625-4009-a133-823af9d762e5
# ╠═99c8bd6c-5a17-4e5c-a509-f0987f78c667
# ╠═376271a2-9eb1-4a20-a2e4-b8177ca3806a
# ╠═02d3beba-75da-4ebd-920a-6db09e0cfd4c
# ╠═06388b97-ccc1-4257-bb22-edf565f3a87f
# ╠═4feb37dc-0197-4441-8a02-8ea4c1e09c3d
# ╠═2c6c6efd-e488-4950-9b8d-8373ff3f73cf
# ╠═db32cfc3-b6b6-4575-b9ca-8d2f73f740ca
# ╠═90c02493-6af0-4553-adb0-9938d120ba1a
# ╠═c208c13d-d673-466f-a3c1-6b3a3005ef51
# ╠═409c7fce-ba47-4a72-9ba6-b90b2bbc1653
# ╠═9ee2717e-6b55-4f5d-b296-bbd2a07d651b
# ╠═acd0a5cb-b22c-4771-9d58-ad6cc0669aa1
# ╠═ef694de8-8a0f-437d-8820-d7ad71576e0f
# ╠═74ed854a-b645-40ff-98a0-1f5e25ef5892
# ╠═05f6a153-4982-438b-9414-1ae4d2299856
# ╠═f70769b6-8c7d-4ef6-a9d2-cd0a7209af3c
# ╠═fa366eb6-e55f-4c4a-b027-ba978e5d986a
# ╠═4514ab64-4d9f-4ae8-a88f-91ee4137db47
# ╠═82325283-9ff3-44c7-bf23-057d60b95081
# ╟─76a40fd1-c010-4016-99b8-a597a12f7ad7
# ╠═beccb9ff-6ef4-42f5-82a4-aaa7384d6673
# ╠═e7e23a9b-6191-46f5-9b8f-25f534888313
# ╟─e61fce66-e4cc-4f2e-b19b-8a00807e043d
# ╠═64ba2df3-4dd4-44ff-acd4-d7c8f9dedb67
# ╠═06e78ad9-3f3f-4a2f-8649-0b9e73e4003d
# ╠═db2bc0cf-07dc-432b-b74a-adb9dca6852b
# ╠═bbcfb9fc-97b8-445b-8d52-9d9ccd6d5690
# ╠═d2915f20-7ad1-463b-8ed0-aca5cc227967
# ╠═65e8b2d5-f193-4986-b20c-6a86798bc036
# ╠═6183e222-e6fd-4280-a79a-df049f28701d
# ╠═388f6e42-8a10-458c-9b23-9e16db45db82
# ╠═65a1479c-f549-46a2-a274-7849c4a5b521
# ╠═9aba231a-0606-4721-ad14-745d40b13bd8
# ╠═afe15611-4779-47f7-9517-f6bd71021ca0
# ╠═ddd232f7-9974-482a-ba57-f35ce8cca9dc
# ╟─27590e20-a91b-4e1b-8a69-ac2373849a9f
# ╠═91d7393d-f8fb-49a1-ade0-6a4d3650ff00
# ╠═12df4a54-1450-4bff-9509-298aa1604664
# ╟─d196ab6f-5c67-4efb-a44d-02fb80fcd970
# ╠═185d1a7f-b524-4d2f-8b08-02c20b5c7dc5
# ╠═a0726b0a-5864-4323-869c-fb9d3b533473
# ╠═60e83fd4-6cbe-4e4a-a525-2baf25246495
# ╠═c3a0cceb-1c58-4463-9b3b-524fa0acd731
# ╠═a4439729-6e8e-4910-aed2-e893319b8b27
# ╠═bb581139-1ae3-4347-80f1-426178c4a47b
# ╠═68854811-b485-4222-ad9d-1a250199cc9d
# ╠═35a5c725-b392-4bf3-b6a0-bf81fa4883b4
# ╠═0413e2d7-25b2-4d16-b6bd-f5de2f66857d
# ╠═ab6bbe39-88e3-46e6-b336-c45ba835e046
# ╠═ba3bbb87-75e4-4c69-ab60-bc78d86e7045
# ╠═dfe95808-a81e-48e0-8dc2-f831ef73c2bc
# ╟─27c86d35-b0a4-4512-9e95-c0caba794336
# ╟─52234463-2fc7-468c-9aeb-40373336ada8
# ╠═cf290101-b1b1-44b7-b6d5-9c9c09ab1d54
# ╟─81b9522b-c15b-45af-b690-e2de1ac93e2f
# ╠═1269827a-7615-48e1-917e-cda866c0694a
# ╟─2afbb8b8-bd7b-4817-9904-c0ed1125e5ad
# ╠═4dcc5e03-a682-4ddd-8c0b-f2dfb2b5f28d
# ╠═b360e2ce-c208-4c93-9698-8ad61295a8b3
# ╟─9c708c32-d76f-481a-9e07-8d4d3f2f8c79
# ╠═718a7d76-83dc-42fb-943c-f030bab68567
# ╠═910ebc66-fc43-4a11-a6b4-e51aa578b57b
# ╟─336ca4b6-ec6e-4f65-8ad1-a7d2dfa70eaa
# ╠═7e8dc59a-c268-4cd2-a57b-15c3ba93bfa0
# ╠═ef3b3bb5-f6ce-480b-9af9-934ba8c14b6d
# ╠═b828966d-fc34-4769-849c-3207f9c386b0
# ╠═544fd1b0-677a-442a-9b6d-f5f0e6bfdafc
# ╠═ff361325-a00c-4075-9039-2d0fa698ada1
# ╠═7ca28df4-a1b3-4f68-bdba-a85801b4189f
# ╠═f0b5524c-48b2-4ddf-bf52-5cbf77e762a6
# ╠═72fccc1d-8e90-4934-b8be-b0f23744032a
# ╠═578a9d43-15c9-432a-9c7f-482dd51dbd59
# ╠═ad018877-3066-4e1b-aff4-6cdc72d7a759
# ╠═e9c4d5c9-4966-4d93-91ed-fbaf2043e2b4
# ╠═abad3302-fd97-48ec-8390-d060cbfa7a51
# ╠═fcafd6ee-0f75-4e9b-9229-1e15a9530ec3
# ╠═f3373416-8749-40c5-aa40-48b6318d28db
# ╠═1b1df0d6-68a5-48b2-8eca-a88cf01a4968
# ╠═f90eb10b-06cb-4957-b3be-c99799f4cb42
# ╠═85f39208-97f5-4435-9acb-7eebb8102ff1
# ╠═8fbdcf3d-9534-4d61-98d8-e5ef1b1d12a0
# ╠═a0e8520c-c53b-4829-9644-8318364a624d
# ╠═626dfee8-d0ce-4f61-9f7b-44c0be92bcc6
# ╠═53e65a9e-1198-4cbe-975c-fcf42e9bcfd2
# ╟─358923ce-1f30-41da-9820-20e60a23f278
# ╟─b564669e-f312-4f37-ab88-8cd4487e6a00
# ╟─7678c74b-8d19-423c-acf5-e404f39b822f
# ╟─f727dd62-cc94-4495-95a4-95fa7931bb9d
# ╟─1b4e28e4-0dae-4f4b-a38e-ba7a98d6923d
# ╠═175f2ebc-fb8b-4b5e-97f0-7ad7a101e3d1
# ╟─ae8305fa-a6b3-4d97-8ffc-2db511dfce38
# ╠═99dfc8a0-fe0f-4ca1-80fe-7a51f2f7514d
# ╠═2e0dd925-5b56-456d-bfe5-ccb51e4d063d
# ╠═7c675aa7-aafa-4d47-a919-4926ad79e6f1
# ╠═af6dbc72-ea9f-4fb9-837f-d682a19bf3d2
# ╟─96269e36-0281-481c-a61c-e457cd8b7919
# ╟─bdcc23a7-fad1-41bb-ba6c-9a5a4b5aa48f
# ╠═d3479ed1-25e9-4702-a006-2646d7f1475e
# ╠═bf421819-3a18-48f4-9b7c-492d5a1c8f66
# ╠═ea8e0ebd-264a-44c9-9eff-1dab660d11d4
# ╠═c161f062-04a1-4710-afde-9f31a285b02c
# ╠═a5365491-4e27-45b9-b298-8c01714b320d
# ╠═02a2c315-558d-4a6b-9cd5-5864f43297c5
# ╠═342ff748-c86b-4347-8592-0254a4889668
# ╠═0d58abdc-98f4-462d-b027-e21efdc34376
# ╠═5c440b29-0a18-4be6-b2cc-ac369e66a269
# ╠═bfc25d2f-ced2-49ad-9ee6-75c5c89d4b13
# ╠═81c19f22-62a2-4f14-a3e0-80adaa8de7dd
# ╠═9e0d741f-b59c-4613-b112-db485bb81a27
# ╠═1dd25ff2-d375-4441-b635-327ebbd42f8b
# ╠═6e346efd-9b7f-48e3-bcd1-33103e43c9c5
# ╟─f3de1ed6-4226-428a-9f17-bac02113c8ef
# ╠═cd5563d7-6dc1-4aec-940e-940a53b630d1
# ╠═d5d8f39a-a4c7-4be5-89b7-606faee68441
# ╠═c2783ea6-59bb-4820-b5ec-ef1737b75f55
# ╠═7d8fd7ec-de78-4286-a140-e2e3f7e927d5
# ╠═68bc3169-9fba-46d8-b712-5561ab3d38f5
# ╟─696771be-5bd1-461d-a66e-7180c8e4d883
# ╠═a4f4bd49-7abf-4fee-addd-f3e46cb0c969
# ╠═1fb93f2f-0bd3-4bcf-8e12-791240de0a8e
# ╠═9509f3ae-eea1-414f-b01e-423bf55b281f
# ╟─4f0d6b2c-1ddb-4eed-ac0f-47b215d3cfc5
# ╠═76e7ec02-f2d8-4e41-a7d2-3db6a9f7a3f1
# ╠═ec316bdc-0a3c-4cd2-832a-0151fc286f7c
# ╠═6f92ad8f-285d-4405-a255-30fd84446f0d
# ╠═e1efe03f-fac8-4bcd-8ae6-9e83b54ab449
# ╟─125cfdbe-09e0-4c20-84c3-117e61bec1f3
# ╠═cac093d1-33b2-4a14-9d54-8ff6813f0929
# ╠═de548dee-eead-4c00-97a5-8c5679b0367a
# ╠═e101279e-5b6c-4ca6-8f52-720599cdc792
# ╟─8e5a8e4d-1bec-4c63-9e96-77593357d063
# ╠═bf157b74-14c4-49f4-a041-bc963dbe5370
# ╠═8ea02c1a-f22e-4034-89a6-b41a2b19bd86
# ╠═190a1cd3-bf39-43db-b3ba-117fff572cce
# ╠═4ab9914d-2028-46a0-823d-03e95fb1c1d5
# ╠═03a6436a-178f-4676-ab15-dc46e5945b43
# ╠═f161fecb-b470-4acd-8c3b-ac963e06b9c2
# ╟─4747b516-453c-4c38-be36-12697d23ecdb
# ╠═aa8043ae-9843-448c-bf83-4d2807bc1e68
# ╠═fbd96575-fb29-4b66-8e49-014222fefd9c
# ╠═1c465cf3-9d33-4ca8-ac24-d7d2367ce47e
# ╠═b6ea00b1-3ef7-4b2c-b277-e8bfeb08e4e4
# ╠═7e6d8183-7caa-4535-8ac2-a6825d64ded4
# ╠═eeafa2c0-924c-483a-ba0b-e274a9e54d2a
# ╠═e3a45f13-24e1-4048-8305-6ffc01f9af5f
# ╟─dcfa8083-8d0f-40b5-93f8-a59c12e45cb9
# ╠═e2cfadc1-157e-40da-b9be-82fc8f7d5333
# ╠═53c967ed-8a04-4933-8eaf-d4b1fad37530
# ╠═31d6c661-7474-4a60-93fd-84a2465bf0f1
# ╠═09e63a6b-74ec-405e-bc49-3811f140533e
# ╠═8ecbdf26-932c-450c-ba2c-df1cc86d0962
# ╠═ec0d2cdb-aafc-4154-9506-e4fa6555a2c0
# ╠═2cba3a7e-09fc-4c79-b70f-423c37ad1c20
# ╠═8454147b-1ca3-4c20-8f8f-3eb0f9a63205
# ╠═ee5ab1fa-586f-4e1a-a650-70c1307eac06
# ╠═4ea98012-2249-4780-bc64-22622392df79
# ╠═e4f1f96d-c565-4c0f-b7f5-4791f7a2f19f
# ╠═1ddd2e0b-907e-4163-af90-5b121ce67617
# ╠═9252e165-3059-496f-b9b1-c85f2cdacb12
# ╠═910a7b75-18cb-46ee-aebf-afdf70402747
# ╠═db0dcac9-b965-41d8-aa5b-e092be22e5cd
# ╠═69c5d767-43de-4dc9-adfb-780b9969fdb1
# ╠═ee2001dd-09a7-4d12-8f8e-a14482990eef
# ╠═d36de2f1-ba3f-4591-9843-f8a3caa3c010
# ╠═a91ba0f1-35cc-44eb-81ba-a4b016e8a18e
# ╠═fc2ed2d7-7751-4e62-a61f-8552494db945
# ╠═2f1930ee-cdb2-4791-83e9-38bb96fa71a5
# ╠═ca9dd14c-79e8-4623-a343-11933c7b2108
# ╠═cf015ad5-e812-4261-9e97-2536ab1c6742
# ╠═57b23606-218b-425e-987b-e55754484eef
# ╠═0b09a909-c6f4-4f7c-b2ba-8e595918002e
# ╠═8b7ebbc2-f67b-4580-81d7-bd29329ff679
# ╠═8d28f254-ab2a-4dc8-bef9-15505504cdee
# ╠═565ce9a2-1fa3-4799-b4c6-1b5ac4473681
# ╠═047d2a25-abb3-4e97-bddf-c13c7c2aefcc
# ╠═397bad9d-e5f3-43fc-8f65-fe69fda4c31e
# ╠═92d64706-4da7-48f7-b891-d2ed75e1ae3e
# ╟─4eb9b4d5-4e09-44cb-acc7-b43afa41554b
# ╠═19c33fed-b4bb-46eb-a5d3-38b26870277c
# ╠═38da0325-7075-4277-bba8-f7fb1420f803
# ╠═ea0376d3-b7a1-4515-8a2d-b70f87566bc0
# ╠═fe7c2d3a-57c2-439c-9fc7-f342bc4126cd
# ╠═fdb91b27-01a9-4475-8393-f2ff2b70968b
# ╠═419a0a63-c53d-40e1-bb4e-e97d01833123
# ╠═b6872b87-bf26-488e-928d-c4eb052df62a
# ╠═1d54de4f-832a-4f80-b8dd-8767e8cf5145
# ╠═fc47c8b4-9703-46fb-8559-517826fa7d6f
# ╠═4b7a37c4-d08f-492a-aa69-0eb434444a68
# ╠═afb01af5-0a81-43c3-baf2-292fb0c4e3c2
# ╟─100699a0-b09a-4790-9c7c-3ff2d831908b
# ╠═5f0ee59f-458e-48d5-bcd4-591f735e2596
# ╠═eb54ac0e-4135-4cdb-b0fe-0aff5dedbe79
# ╠═1fa64af2-1965-4748-8c79-78b62acf8060
# ╠═fdd08dc8-5f22-4e54-ae7a-cb41a1183d47
# ╠═a067b798-795c-4a57-9079-f64cdc50d35d
# ╠═be6c5a27-755d-429e-8e1d-97c49ecb53c5
# ╠═9c623025-4b7c-4c64-b9a4-b1d8e7bb0e2f
# ╠═7448d912-79f8-41e9-ad93-e1e9b6d731b4
# ╠═7f9e8486-4674-452c-82b1-0666b8713d33
# ╠═bdbdd861-463a-409a-9dd0-edb1a973b7f2
# ╟─1d6219bc-575b-4703-a058-ec50fe276e15
# ╠═cf7fbefa-e91c-4908-b2e5-75d8c28f6611
# ╠═5d78a235-7db8-4441-8bd3-ad1ecc2808c6
# ╠═3b4b07d4-0701-40db-b056-c84dd075f4c1
# ╠═7ce99bc4-f968-4878-98e0-9fffc94cc5f8
# ╠═a17c9fc2-63f1-4707-bdb9-0aa8da50a609
# ╟─e7e9d13b-8d82-4fca-b2fd-9b839207081e
# ╠═f6d63720-c3eb-4e90-bebc-f859c582602c
# ╠═3054bbd7-845d-4fc7-a8c0-7ab73d321457
# ╠═212ce0e8-ffe3-4531-9e02-d872ca12d1b8
# ╠═a89c649b-e12d-4668-acca-b813eaaafcca
# ╠═c3e2ed93-8063-432b-8a9c-26ddaf4a45c5
# ╠═da5658a7-0cd3-4927-989c-3216f7774cef
# ╠═a9bf4f3d-25b2-4016-bfc8-ef8500bcd3e1
# ╠═f2571662-10cf-462b-a9bc-8f2c7e7760bc
# ╠═23086bf0-54e0-4930-b161-5cca60e4166b
# ╠═e734f80a-3792-4d32-ab20-34f85707a590
# ╠═4dc9c13c-c371-46a5-bb60-dffa0eac9920
# ╠═46780314-a7dc-4073-a9d6-30fafb31a7f6
# ╠═2d52ca70-1ee9-4ac9-b7cc-630c12f262fd
# ╠═dcbc72be-820a-4b2b-be72-32aef3e92f52
# ╠═f2edb22d-acfa-411d-8259-21cf13f4ce4f
# ╠═58cf45d9-4e3e-4056-84ad-06a3efb682ca
# ╠═47eae398-661b-4a35-be30-16547c71fe7b
# ╠═21b9bd18-4e4a-401a-b7a8-f361d73526b6
# ╠═d6e964d1-c6bc-4659-978f-ce890fd6401e
# ╠═c5d8462a-5526-4e30-804d-62fa38064f39
# ╠═00e4b8d6-4c25-44f5-8f22-e448e861989e
# ╠═c1821487-7509-4b20-bcf1-3b81da2fcebb
# ╠═c36bd405-4990-411c-8ec4-4e2a57f22dc8
# ╠═bdc0a9e8-278a-4148-a629-b0e96228dd8b
# ╠═354fcc56-7230-48f8-b1d4-b3cf606e495f
