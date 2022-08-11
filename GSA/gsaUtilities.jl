using PolyChaos
using LinearAlgebra
using CSV
using DelimitedFiles
using DataFrames
using Dates
using ColorSchemes
using StatsBase
using Random

export processInputs,
       getInputNames,
       processInputsBg,
       getInputNamesBg,
       processMissingValues,
       processOutputs,
       buildMultivariateBasis,
       buildCoefficientMatrix,
       solvePCE,
       solveRegPCE,
       performGSA,
       gsaMain,
       gsa,
       processMainEffects,
       getSubsetMI,
       getSubsetIndex,
       processTimeInfo,
       plotMainEffects,
       plotInteractionEffects,
       bootstrapGSA,
       getBootstrapSummary,
       regularized_fit,
       regularized_plot,
       train_test_split

"""
Take in path to original inputs for CME and scale to [0-1] range 
"""
function scaleInputs(rawInputsPath, lb, ub)
    inputRaw = CSV.read(rawInputsPath, DataFrame)[!, Not("Column1")]


    return scaledInputs
end

"""
Take in scaled inputs for CME and read and filter them using supplied 
arguments.
"""
function processInputs(scaledInputs::DataFrame, retainedRunIdx; useBg=true)
    if !useBg
        inputsFiltered = inputRaw[!, Not(["BrFactor_ADAPT",
                                    "PoyntingFluxPerBSi",        
                                    "LperpTimesSqrtBSi",
                                    "Helicity",
                                    "bgRunIdx",
                                        ])
                                    ]
    else
        inputsFiltered = inputRaw[!, Not(["Helicity",
                                    "bgRunIdx",
                                        ])
                                    ]
    end

    X = Matrix(inputsFiltered[retainedRunIdx, :])
    return X
end


"""
Take in path to scaled inputs for CME and read and filter them using 
supplied arguments.
"""
function processInputs(inputsPath::String, retainedRunIdx; useBg=true)
    inputRaw = CSV.read(inputsPath, DataFrame)
    X = processInputs(inputRaw, retainedRunIdx; useBg=useBg)
    # if !useBg
    #     inputsFiltered = inputRaw[!, Not(["BrFactor_ADAPT",
    #                                 "PoyntingFluxPerBSi",        
    #                                 "LperpTimesSqrtBSi",
    #                                 "Helicity",
    #                                 "bgRunIdx",
    #                                     ])
    #                                 ]
    # else
    #     inputsFiltered = inputRaw[!, Not(["Helicity",
    #                                 "bgRunIdx",
    #                                     ])
    #                                 ]
    # end

    # X = Matrix(inputsFiltered[retainedRunIdx, :])
    return X
end

"""
Function to process inputs for background solar wind runs alone.
Assume that input file is supplied in the standardized 0-1 scaling, with following
columns:
BrMin, BrFactor_ADAPT, nChromoSiAWSoM, PoyntingFluxPerBSi, LperpTimesSqrtBSi,
StochasticExponent, rMinWaveReflection

"""
function processInputsBg(inputsPath, retainedRunIdx)
    inputRaw = CSV.read(inputsPath, DataFrame)
    X = Matrix(inputRaw[retainedRunIdx, :])
    return X
end

"""
Fetch parameter names for background solar wind runs
"""
function getInputNamesBg(inputsPath)
    inputRaw = CSV.read(inputsPath, DataFrame)
    return names(inputRaw)
end


function getInputNames(inputsPath; useBg=true)
    inputRaw = CSV.read(inputsPath, DataFrame)
    if !useBg
        inputsFiltered = inputRaw[!, Not(["BrFactor_ADAPT",
                                    "PoyntingFluxPerBSi",        
                                    "LperpTimesSqrtBSi",
                                    "Helicity",
                                    "bgRunIdx",
                                        ])
                                    ]
    else
        inputsFiltered = inputRaw[!, Not(["Helicity",
                                    "bgRunIdx",
                                        ])
                                    ]
    end
    return names(inputsFiltered)
end

function processMissingValues(outputRaw)
    missingIdx = [findall(ismissing, outputRaw[:, i]) for i in 1:size(outputRaw, 2)]
    mostMissingsCol = argmax(length.(missingIdx))
    # Identify column with greatest number of missings
    dMissing = diff(missingIdx[mostMissingsCol])
    # if elements are missing at beginning and end
    if maximum(dMissing) > 1
        trimmedRange = (argmax(dMissing) + 1):(argmax(dMissing) + maximum(dMissing) - 1)
    # if elements are missing only at beginning or only at end
    elseif maximum(dMissing) == 1
        if missingIdx[mostMissingsCol][1] > 1 # missing only at end
            trimmedRange = 1:(missingIdx[mostMissingsCol][1] - 1)
        else # missing only at beginning
            trimmedRange = (missingIdx[mostMissingsCol][end] + 1):size(outputRaw, 1)
        end
    end
    return trimmedRange
end

"""
Function to read and process shifted / unshifted outputs. For background solar
wind runs, only works with unshifted runs.
"""
function processOutputs(outputPath, retainedRunIdx; QoI="Ur", useShifted=false)
    if useShifted
        outputRaw = readdlm(joinpath(outputPath, QoI * "SimTrimmed.txt"))
        replace!(x -> x == "missing" ? missing : x, outputRaw)
        # trim off missing values!
        trimmedRange = processMissingValues(outputRaw)
        Y = outputRaw[trimmedRange, :]
    else
        outputRaw = readdlm(joinpath(QOIS_PATH, QoI * "Sim_earth.txt"))
        Y = outputRaw[:, retainedRunIdx]
    end

    return Array{Float64, 2}(Y')
end


# function to build multivariate basis for PCE
function buildMultivariateBasis(D, P)
    # D is dim of stochastic space
    # P is degree of PCE

    univariateBasis = Uniform01OrthoPoly(P) # Monic case
    # univariateBasis = Legendre01OrthoPoly(P)

    return MultiOrthoPoly([univariateBasis for i in 1:D], P)
end

# function to build PCE
function buildCoefficientMatrix(X; pceDegree=2)
    nd = size(X, 2) # dimension of stochastic space
    multivariateBasis = buildMultivariateBasis(nd, pceDegree)
    # monic is false, but normalizing is true, alternately both are true!
    # revise this later to add it as an argument.
    A = PolyChaos.evaluate(X, multivariateBasis, true, true)'
    # A = evaluate(X, multivariateBasis, false, true)'
    return Matrix(A)
end

# function to regress PCE
function solvePCE(A, y; regularize=false, fitIntercept=false)
    if fitIntercept==true
        β =  A \ y
        return β
    else
        
        β0 = mean(y, dims=1)
        ACoeffs = A[:, 2:end]
        ACentered = ACoeffs .- mean(ACoeffs, dims=1)
        βCoeffs = ACentered \ y
        return vcat(β0, βCoeffs)
    end
end

"""
Function to solve regularized linear system for PCE. By default, regularization parameter
λ is 0 i.e. it performs OLS.
"""
function solveRegPCE(A, y; λ::Number = 0)
    # Let's do this with centering and see the effect!
    β0 = mean(y, dims=1)
    ACoeffs = A[:, 2:end]
    ACentered = ACoeffs .- mean(ACoeffs, dims=1)
    βCoeffs = (ACentered' * ACentered + λ * I) \ (ACentered' * y)
    return vcat(β0, βCoeffs) 
end

"""
Function to solve PCE when vector of reg parameters is supplied, i.e. one for each time point.
"""
function solveRegPCEVar(A, y, λ::AbstractArray)
    # Let's do this with centering and see the effect!
    β0 = mean(y, dims=1)

    ACoeffs = A[:, 2:end]
    ACentered = ACoeffs .- mean(ACoeffs, dims=1)

    m, n = size(ACoeffs, 2), size(y, 2)
    βCoeffs = zeros(m, n)
    for i in 1:n
        βCoeffs[:, i] = (ACentered' * ACentered + λ[i] * I) \ (ACentered' * y[:, i])
    end
    return vcat(β0, βCoeffs) 
end

# function lasso_convex(y::Matrix, A::Matrix, τ::Number)
#     # β0 = mean(y, dims=1)
#     # ACoeffs = A[:, 2:end]
#     # ACentered = ACoeffs .- mean(ACoeffs, dims=1)
#     m, n = size(A, 2), size(y, 2)
#     βCoeffs = zeros(m, n)
#     C = Array(Diagonal(ones(m)))
#     for i in 1:n
#         xopt = Variable(m)
#         problem = minimize(norm(A * xopt - y[:, i], 2))
#         problem.constraints += norm(C*xopt, 1) <= τ
#         solve!(problem, SCS.Optimizer(verbose=false), verbose=false)
#         xopt = xopt.value
#         βCoeffs[:, i] = xopt
#     end
#     return βCoeffs
#     # return vcat(β0, βCoeffs)
# end


# function to return subset of multi-index for particular effect
function getSubsetMI(multiIndex, effectIdx)
    subsetMI = []
    m, n = size(multiIndex)
    for i in 1:m
        # maybe set notation would simplify this operation?
        push!(subsetMI, (all(multiIndex[i, effectIdx] .> 0)) & (multiIndex[i, setdiff(1:n, effectIdx)] == zeros((n - length(unique(effectIdx))))))
    end
    return Array{Bool, 1}(subsetMI)
end

function getSubsetIndex(multiIndex, effectIdx)
    subsetMI = []
    m, n = size(multiIndex)
    for i in 1:m
        # maybe set notation would simplify this operation?
        push!(subsetMI, (all(multiIndex[i, effectIdx] .> 0)) & (multiIndex[i, setdiff(1:n, effectIdx)] == zeros((n - length(unique(effectIdx))))))
    end
    return multiIndex[Array{Bool, 1}(subsetMI), :]
end

"""
Obtain confidence intervals for PCE given coefficients.
"""
function getConfidenceIntervals(β)
    meanPCE = [β[1, t] for t in 1:size(β, 2)]
    stdPCE  = [sqrt(sum(β[2:end, t].^2)) for t in 1:size(β, 2)]

    return meanPCE, stdPCE
end

function getConfidenceIntervals(X, Y; 
                        regularize=false, 
                        pceDegree=2, 
                        lambda=0,
                        fitIntercept=false
                        )

    nEffects = size(X, 2)
    nTimePts = size(Y, 2)

    gsaIndices = zeros(nEffects, nEffects, nTimePts);
    # Diagonal elements contain main effects
    # Off diagonal elements contain interactions

    A = buildCoefficientMatrix(X; pceDegree=pceDegree)
    if regularize
        β = solveRegPCE(A, Y; λ=lambda)
    else
        β = solvePCE(A, Y; regularize=regularize, fitIntercept=fitIntercept)
    end

    meanPCE, stdPCE = getConfidenceIntervals(β)
    return meanPCE, stdPCE
end

"""
Get confidence intervals with varying regularization.
"""
function getConfidenceIntervalsVar(X, Y, lambdaVals; 
                            pceDegree=2, 
                            fitIntercept=false
                            )

    nEffects = size(X, 2)
    nTimePts = size(Y, 2)

    gsaIndices = zeros(nEffects, nEffects, nTimePts);
    # Diagonal elements contain main effects
    # Off diagonal elements contain interactions

    A = buildCoefficientMatrix(X; pceDegree=pceDegree)
    β = solveRegPCEVar(A, Y, lambdaVals)

    meanPCE, stdPCE = getConfidenceIntervals(β)
    return meanPCE, stdPCE
end


function performGSA(inputsPath, outputPath; gsa_kwargs...)
    # process inputs
    X = processInputs(inputsPath, retainedRunIdx; useBg=useBg)
    # A = buildCoefficientMatrix(inputsPath, retainedRunIdx; useBg=useBg, pceDegree=pceDegree)
    # process outputs
    Y = processOutputs(outputPath, retainedRunIdx; 
                    QoI=QoI,
                    useShifted=useShifted
                    )


    # use X and Y to get Sobol Indices
    gsaIndices = gsa(X, Y; 
                    regularize=regularize, 
                    pceDegree = pceDegree
                    )

    return gsaIndices
end

# function to calculate _only_ main effects!
function gsaMain(β::AbstractArray; nEffects = 7, pceDegree=2, multiIndex=nothing)
    nTimePts = size(β, 2)
    mainEffects = zeros(nEffects, nTimePts);
    # Diagonal elements contain main effects
    # Off diagonal elements contain interactions
    if isnothing(multiIndex)
        multiIndex = buildMultivariateBasis(nEffects, pceDegree).ind
    end
    for t in 1:nTimePts
        varF = sum(β[2:end, t].^2)
        for i in 1:nEffects
            subsetMultiIndex = getSubsetMI(multiIndex, [i, i])
            varSubset = sum(β[findall(subsetMultiIndex), t].^2)
            mainEffects[i, t] = varSubset / varF
        end
    end
    return mainEffects
end

# function to calculate tensor of main and joint effects
function gsa(X, Y; regularize=false, pceDegree=2, lambda=0, fitIntercept=false)

    nEffects = size(X, 2)
    nTimePts = size(Y, 2)

    gsaIndices = zeros(nEffects, nEffects, nTimePts);
    # Diagonal elements contain main effects
    # Off diagonal elements contain interactions

    A = buildCoefficientMatrix(X; pceDegree=pceDegree)
    if regularize
        β = solveRegPCE(A, Y; λ=lambda)
    else
        β = solvePCE(A, Y; regularize=regularize, fitIntercept=fitIntercept)
    end

    multiIndex = buildMultivariateBasis(nEffects, pceDegree).ind
    for t in 1:nTimePts
        varF = sum(β[2:end, t].^2)
        for i in 1:nEffects
            for j in 1:nEffects
                subsetMultiIndex = getSubsetMI(multiIndex, [i, j])
                varSubset = sum(β[findall(subsetMultiIndex), t].^2)
                gsaIndices[i, j, t] = varSubset / varF
            end
        end
    end
    return gsaIndices
end

"""
Calculate GSA with optimal regularization values as input!
"""
function gsaRegularized(X, Y, lambdaVals; pceDegree=2, fitIntercept=false)
    nEffects = size(X, 2)
    nTimePts = size(Y, 2)

    gsaIndices = zeros(nEffects, nEffects, nTimePts);
    # Diagonal elements contain main effects
    # Off diagonal elements contain interactions

    A = buildCoefficientMatrix(X; pceDegree=pceDegree)

    β = solveRegPCEVar(A, Y, lambdaVals)
   
    multiIndex = buildMultivariateBasis(nEffects, pceDegree).ind
    for t in 1:nTimePts
        varF = sum(β[2:end, t].^2)
        for i in 1:nEffects
            for j in 1:nEffects
                subsetMultiIndex = getSubsetMI(multiIndex, [i, j])
                varSubset = sum(β[findall(subsetMultiIndex), t].^2)
                gsaIndices[i, j, t] = varSubset / varF
            end
        end
    end
    return gsaIndices
end

# calculate with β as input!
function gsa(β::AbstractArray; nEffects=7, pceDegree=2)
    @assert factorial(nEffects + pceDegree) / (factorial(nEffects) * factorial(pceDegree)) == size(β, 1)
    nTimePts = size(β, 2)
    multiIndex = buildMultivariateBasis(nEffects, pceDegree).ind
    gsaIndices = zeros(nEffects, nEffects, nTimePts);
    for t in 1:nTimePts
        varF = sum(β[2:end, t].^2)
        for i in 1:nEffects
            for j in 1:nEffects
                subsetMultiIndex = getSubsetMI(multiIndex, [i, j])
                varSubset = sum(β[findall(subsetMultiIndex), t].^2)
                gsaIndices[i, j, t] = varSubset / varF
            end
        end
    end
    return gsaIndices
end

function processMainEffects(gsaIndices)
    nEffects = size(gsaIndices, 1)
    nTimePts = size(gsaIndices, 3)
    mainEffects = zeros(nEffects, nTimePts)
    for i in 1:nTimePts
        mainEffects[:, i] = diag(gsaIndices[:, :, i])
    end
    return mainEffects
end

# function to make plots of everything (this will require time information)
"""
Process time to enable plotting of time information on graph.
Problematic: Trim index information. Need to reorganize data so it is 
easier to deal with.
"""
function processTimeInfo(timeData; trimIndices = (39, 141))
    if timeData isa Vector{String}
        obsTimes = DateTime.(chomp.(timeData))
    else 
        obsTimes = DateTime.(timeData)
    end
    startTime = obsTimes[1]
    obsTimesTrimmed = obsTimes[trimIndices[1]: trimIndices[2]]
    return startTime, obsTimesTrimmed
end

function plotMainEffects(mainEffects, timeData, inputNames;
                        palette=palette(:tab10, rev=true),
                        trimIndices=(1, 720),
                        tickStep=72,
                        tickFormat="dd-u",
                        title="Title",
                        lineWidth=0.0,
                        barWidth=2,
                        dpi=1000
                        )
    # we will first permute these so they show up with correct convention in 
    # our bar plot

    # only columns are reversed after transpose, we are not changing the time series.
    mainEffectsReversed = reverse(mainEffects', dims=2)
    startTime, obsTimesTrimmed = processTimeInfo(timeData; trimIndices=trimIndices)
    obsTimeTicks = range(obsTimesTrimmed[1], 
                        obsTimesTrimmed[end], 
                        step=Hour(tickStep)
                        )
    xTicks = findall(in(obsTimeTicks), obsTimesTrimmed)
    labels = Dates.format.(obsTimeTicks, tickFormat)
    groupedbar(
            mainEffectsReversed,
            bar_position=:stack,
            bar_width=barWidth,
            legend=:outertopright,
            label=permutedims(reverse(inputNames)),
            xticks=(xTicks, labels),
            xminorticks=12,
            figsize=(1000, 600),
            color=[palette[i] for i in 1:size(mainEffectsReversed, 2)]',
            line=(lineWidth, :black),
            title=title,
            xlims=(1, length(obsTimesTrimmed)),
            ylims=(0, 1),
            dpi=dpi,
            framestyle=:box,
            )
    # plot!(xticks=(ticks, labels))
    plot!(xlabel = "Start Time: $(Dates.format(startTime, "dd-u-yy HH:MM:SS"))")
    plot!(ylabel = "Main Effects")

end




"""
Replicate Python function. Plot ONLY one half of the Matrix
and include text labels to annotate.
"""
function plotInteractionEffects(gsaIndices, 
                            timeData,
                            inputNames;
                            trimIndices=(1, 720), 
                            timeIdx=nothing,
                            dpi=1000,
                            color=:viridis
                            # summaryPlot="mean"
                            )
    if !isnothing(timeIdx)
        interactions = LowerTriangular(gsaIndices[:, :, timeIdx])
        _, obsTimes = processTimeInfo(timeData; trimIndices=trimIndices)
        plotTime = obsTimes[timeIdx]
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
                              xticks=(1:7, xlabels),
                              yticks=(1:7, xlabels),
                              fillalpha=0.7,
                              grid=false,
                              framestyle=:box,
                              dpi=dpi
                            )

    thresh = maximum(interactions) / 2
    fontsize=10
    ann_thresh = [interactions[j, i] >= thresh ? (i,j, text(round(interactions[j, i], digits=2), fontsize, :black, :center)) : (i, j, text(round(interactions[j, i], digits=2), fontsize, :white, :center))
                           for i in 1:nrow for j in 1:ncol]
    

    annotate!(ann_thresh, linecolor=:white)
    # # 
    # return interactionPlot
    return interactionPlot
end

# function to perform bootstrapping

# function drawInputSamples(inputsPath, retainedRunIdx; 
#                         useBg=true,
#                         NSamples = 100
#                         )
    


#     return inputSamples, trainIdx
# end


"""
Function to perform bootstrapping for a given number of replicates and sample size. 
The bootstrapping process is given in: 
Storlie, Curtis B., et al. Implementation and Evaluation of Nonparametric Regression Procedures for Sensitivity Analysis of Computationally 
Demanding Models. 
Reliability Engineering & System Safety, vol. 94, no. 11, Nov. 2009, pp. 1735–63. DOI.org (Crossref), https://doi.org/10.1016/j.ress.2009.05.007.
"""
function bootstrapGSA(X, Y; 
                    regularize=false,
                    pceDegree=2,
                    NReplications = 1000,
                    replace=true,
                    lambda=0,
                    fitIntercept=false,
                    nStart=20,
                    nEnd=100,
                    nStep=10
                    # NSamples = 100
                    )

    A = buildCoefficientMatrix(X; pceDegree=pceDegree)
    # bootstrap sampling
    nSamplesEnd = nEnd
    nSamplesStart = nStart
    samplingRange = range(nSamplesStart, nSamplesEnd; step=nStep)

    nEffects = size(X, 2)
    nTimePts = size(Y, 2)
    
    mainEffectsBootstrap = zeros(nEffects, nTimePts, NReplications, length(samplingRange)); 
    multiIndex = buildMultivariateBasis(nEffects, pceDegree).ind

    for replication in 1:NReplications
        for (iSample, n) in enumerate(samplingRange)
            # println("New sample size: ", n)
            sampleIndex = sample(1:size(X, 1), n, replace=replace)
            ASamples = A[sampleIndex, :]
            YSamples = Y[sampleIndex, :]
            # A = buildCoefficientMatrix(XSamples; pceDegree=pceDegree)
            if regularize
                β = solveRegPCE(ASample, YSamples; λ=lambda)
            else
                β = solvePCE(ASamples, YSamples; regularize=regularize, fitIntercept=fitIntercept)
            end

            # can save some time here by extending method for supplied multiindex, and calculating multiindex outside of both our for loops.
            mainEffectsBootstrap[:, :, replication, iSample] = gsaMain(β; nEffects=nEffects, pceDegree=pceDegree, multiIndex=multiIndex)
        end
        println("Finished replication: ", replication, " for all sample sizes")
    end

    return mainEffectsBootstrap
    # meanEffects = mean(mainEffectsBootstrap; dims=3)[:, :, 1, :]; # take mean across replications and squeeze out dimension
    # stdEffects  = std(mainEffectsBootstrap; dims=3)[:, :, 1, :];  # take std across replications and squeeze out dimension
    # return meanEffects, stdEffects
end

"""
Function to obtain summary of bootstrap procedure results.
"""
function getBootstrapSummary(bootstrapEffects)
    # note specifying the dimension needs knowledge of which index encodes replications!. Not robust!!
    meanEffects = mean(mainEffectsBootstrap; dims=3)[:, :, 1, :]; # take mean across replications and squeeze out singleton dimension
    stdEffects = std(mainEffectsBootstrap; dims=3)[:, :, 1, :]; 
    return meanEffects, stdEffects
end

"""
Function to plot bootstrap summaries
"""
function plotBootstrapSummary(mainEffectsBootstrap;
                            inputNames,
                            nReplications=100,
                            samplingRange=20:10:100,
                            saveDir="./images/Bootstrapping/100Reps/",
                            dRep=1
                            )
    samplingRange = samplingRange
    avgMainEffectsBootstrap = mean(mainEffectsBootstrap; dims=2)[:, 1, :, :];
    for (i, sampleSize) in enumerate(samplingRange)
        dirName = joinpath(saveDir, @sprintf("N%03d", sampleSize))
        mkdir(dirName)
        for rep in 1:dRep:nReplications
            p = bar(inputNames,
                    avgMainEffectsBootstrap[:, rep, i],
                    xrot=20,
                    ylims=(0, 1),
                    bar_width=1.0,
                    fillcolor=:violet,
                    title="Replication " * "$rep" * " samples= " * "$sampleSize",
                    label="",
                    framestyle=:box,
                    dpi=600
                    )
            savefig(joinpath(dirName, @sprintf("N%03dREP%03d_Ur_CR2208.png", sampleSize, rep)))
        end
    end
end


## SECTION TO TEST AND PLOT PREDICTIONS OF SURROGATE

"""
Take in input matrix X and output matrix Y and split it in suitable fashion into train and test sets.
The `ratio` parameter specifies sizes i.e. test size / train size ~ 0.2
"""
function train_test_split(X, Y; ratio=0.2, seed=20220405)
    # Random.seed!(seed)
    shuffledIdx = shuffle(1:size(X, 1))
    # perform splitting
    testLength = floor(Int, ratio * length(runs_to_keep))
    testIdx = shuffledIdx[1:testLength]
    trainIdx = shuffledIdx[(testLength + 1):end]

    XTrain = X[trainIdx, :]
    XTest  = X[testIdx,  :]
    
    YTrain = Y[trainIdx, :]
    YTest  = Y[testIdx, :]

    return XTrain, YTrain, XTest, YTest, trainIdx, testIdx
end

"""
Function to do L2 fit and return predictions as well as original 
simulation runs.
"""
function regularized_fit(X, Y, lambda;
                                ratio=0.2,
                                seed=20220405,
                                pceDegree=2
                                )
    
    XTrain, YTrain, XTest, YTest, trainIdx, testIdx = train_test_split(X, Y;
                                                            ratio=ratio,
                                                            seed=seed
                                                            )
    ATrain  = buildCoefficientMatrix(XTrain; pceDegree=pceDegree)
    ATest   = buildCoefficientMatrix(XTest; pceDegree=pceDegree)
    βTrain  = solveRegPCE(ATrain, YTrain; λ = lambda)
    YPred   = ATest * βTrain

    return XTest, YTest, YPred, testIdx
end

"""
Extend regularized fit to use supplied XTrain, XTest, etc
"""
function regularized_fit(XTrain, YTrain, XTest, lambda;
                        pceDegree=2)
    ATrain  = buildCoefficientMatrix(XTrain; pceDegree=pceDegree)
    ATest   = buildCoefficientMatrix(XTest; pceDegree=pceDegree)
    βTrain  = solveRegPCE(ATrain, YTrain; λ = lambda)
    YPred   = ATest * βTrain

    return YPred
end

"""
Perform K-fold CV and return k - fold CV errors for all times and all values of lambda!
"""
function kFoldCV(X, Y, lambdas; pceDegree=2, nFolds=5)

    nRuns    = size(X, 1)
    nTimePts = size(Y, 2)

    nRegs = length(lambdas)

    kFoldErrors = zeros(nTimePts, nRegs)

    A = buildCoefficientMatrix(X; pceDegree=pceDegree);
    m = size(A, 1)
    lo_size = floor(Int, m / nFolds)
    for (regIdx, lambda) in enumerate(lambdas)
        for tIdx in 1:nTimePts
            err_CV_fold = zeros(nFolds)
            lo_range = 0
            for lo = 1:nFolds
                if lo < nFolds
                    lo_range = (lo_range[end] + 1):(lo_range[end] + lo_size)
                elseif lo==nFolds
                    lo_range = (lo_range[end] + 1):m
                end
                
                A_CV = A[setdiff(1:m, lo_range), :]
                A_test = A[lo_range, :]
                y_CV = Y[setdiff(1:m, lo_range), tIdx]

                b_CV = solveRegPCE(A_CV, y_CV; λ=lambda)
                y_pred = A_test * b_CV
                err_CV_fold[lo] = norm(y_pred - Y[lo_range, tIdx])^2

            end
            kFoldErrors[tIdx, regIdx] = sqrt(sum(err_CV_fold)) / norm(Y[:, tIdx])
            # β = solveRegPCE(A, Y; λ=lambda)
        end
    end
    return kFoldErrors
end

"""
Function to make plots for all test runs across different lambda values.
"""
function regularized_plot(YTest, YPred, testIdx, plotIdx, lambda; ylims=(200, 900))
    pReg = plot(YTest[plotIdx, :], line=(:red, 2), label="Truth")
    plot!(YPred[plotIdx, :], line=(:blue, 2), label="Prediction")
    plot!(ylims=ylims)
    rmse = sqrt(mean((YTest[plotIdx, :] - YPred[plotIdx, :]).^2))
    plot!(title = "RMSE:$(round(rmse, digits=2)) " * " λ:$(round(lambda, digits=2))  Idx:$(testIdx[plotIdx])")
    plot!(titlefontsize=6)
    plot!(legendfontsize=4, fg_legend=false)
    return pReg, rmse
end

"""
Function to plot confidence intervals based on constructed PCE!
"""
function plotMeanStd(Y, meanPCE, stdPCE, obsData, timeData;
                    nSTD = 2,
                    ylims=(200, 900), 
                    ylabel="Ur",
                    trimIndices=(1, 720),
                    obsIdxToPlot=1:577,
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
    meanSim = mean(Y, dims=1)[:]
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
    plot!(obsIdxToPlot, obsData[obsIdxToPlot], line=(:black, 3), label="OMNI")
    # plot!(obsData, line=(:black, 3), label="OMNI")
    # plot!(title=title)
    plot!(ylabel=ylabel)
    plot!(xlabel = "Start Time: $(Dates.format(startTime, "dd-u-yy HH:MM:SS"))")
    plot!(fg_legend=nothing)
    plot!(bg_legend=nothing)
    plot!(framestyle=:box)
    return pCI
end
