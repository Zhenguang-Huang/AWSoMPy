module LHSDesign


using LinearAlgebra
using Random
using Statistics
using NearestNeighbors
using Distributions

"""
    lhsdesign(n::Int64, p::Int64, maxiter::Int64=1, crit::String="maximin")

Compute the Latin Hypercube design for `n` runs and `p` factors. Can improve the design for multiple iterations and uses the `maximin` design criterion. 

# Arguments:
- `n`: Number of runs needed
- `p`: Number of design factors
- `maxiter`: Number of iterations to refine the design (default = 1)
- `crit`: Criterion for evaluating LHS (default = "maximin")
- `dosmooth`: Whether to generate randomly in interval or at midpoint (default = "on")

"""
# function lhsdesign(n::Int64, p::Int64, maxiter::Int64=1, crit::String="maximin", dosmooth::String="on")

#     X, Y = getsample(n, p, dosmooth) # Y returns initially generated pseudorandom sample. 
   
#     if crit=="maximin"
#         bestscore, _ = score(X,crit)
#         for j=2:maxiter
#            x, _ = getsample(n,p,dosmooth)
           
#            newscore, _ = score(x,crit)
#            if newscore .> bestscore
#               X = x
#               bestscore = newscore
#            end
#         end

#     else
#         error("Invalid criterion, try one of 'maximin' or 'correlation'")
#     end
# return X, Y
# end

# Hybrid LHS maximin (Morris and Mitchell)
"""
Finds hybrid LHS/maximin design based on method proposed by Morris and Mitchell (1995). 
"""
function lhsdesign(n::Int64, p::Int64, maxiter::Int64=1, crit::String="maximin", dosmooth::String="on")

    X, Y = getsample(n, p, dosmooth) # Y returns initially generated pseudorandom sample. 
    Z = deepcopy(X)
    if crit=="maximin"
        bestscore, _ = score(X,crit)
        for j=2:maxiter
        #    someRow = sample(1:n, 1)
        #    XOld = X[someRow, :]
           someRows = sample(1:n, 2)
           someColumn = sample(1:p, 1)
           XOld = X[someRows, :]
           X[someRows[1], someColumn] = XOld[2, someColumn]
           X[someRows[2], someColumn] = XOld[1, someColumn]
        #    x, _ = getsample(n,p,dosmooth)
           newscore, _ = score(X,crit)
           if newscore .> bestscore
            bestscore = newscore
           else
            X[someRows[1], someColumn] = XOld[1, someColumn]
            X[someRows[2], someColumn] = XOld[2, someColumn]
           end
        end

    else
        error("Invalid criterion, try one of 'maximin' or 'correlation'")
    end
return X, Y, Z
end




# Helper functions  
function getsample(n,p,dosmooth)
    x = rand(n,p)

    # Return only randomly generated x - this is our pseudo random design
    y = deepcopy(x)
    for i=1:p
        x[:,i] = rank(x[:,i])
    end
    if isequal(dosmooth,"on")
        rs, cs = size(x)
        x = x - rand(rs, cs)
    else
        x = x .- 0.5
    end
    x = x / n
    return x, y
end

function score(x,crit)
    # compute score function; larger is better
    if size(x,1)<2
        s1 = 0;       # score is meaningless with just one point
        s2 = 0;
        return s1, s2
    end

    if crit=="maximin"        # Maximize the minimum point-to-point difference
        # xTransposed = convert{Array{Float64, p}, x'}
        xTransposed = x'

        kdtree = KDTree(xTransposed)
        _, dist = knn(kdtree, xTransposed, 2, true)
        distArray = vecvec_to_matrix(dist)
        s1 = minimum(distArray[:, 2])
        s2 = mean(distArray[:, 2])
    end
    return s1, s2
end



function takeout(x,y)
    # Remove from y its projection onto x; ignoring constant terms
    xc = x .- mean(x)
    yc = y .- mean(y)
    b = (xc .- mean(xc))\(yc .- mean(yc))
    z = y - b*xc
    return z
end

function rank(x)
    # similar to tiedrank; but no adjustment for ties here
    r = zeros(length(x))
    rowidx = sortperm(x)
    # [~, rowidx] = sort(x)
    r[rowidx] = 1:length(x)
    r = r[:]
    return r
end

function vecvec_to_matrix(vecvec)
	someMatrix = zeros(length(vecvec), length(vecvec[1]))
	for vecIdx in 1:length(vecvec)
		someMatrix[vecIdx, :] = vecvec[vecIdx]
	end
	return someMatrix
end


export lhsdesign, getsample, score, takeout, rank, vecvec_to_matrix

end


# elseif crit=="correlation"
#     bestscore = score(X,crit)
#     for iter=2:maxiter
#       # Forward ranked Gram-Schmidt step:
#       for j=2:p
#          for k=1:j-1
#             z = takeout(X[:,j],X[:,k])
#             X[:,k] = (rank(z) .- 0.5) / n
#          end
#       end
#       # Backward ranked Gram-Schmidt step:
#       for j=p-1:-1:1
#          for k=p:-1:j+1
#             z = takeout(X[:,j],X[:,k])
#             X[:,k] = (rank(z) .- 0.5) / n
#          end
#       end
   
#       # Check for convergence
#       newscore = score(X,crit)
#       if newscore <= bestscore
#          break
#       else
#          bestscore = newscore
#       end
#     end

# if crit=="correlation"
#     # Minimize the sum of between-column squared correlations
#     c = cor(x, dims = 1)
#     s = -sum(triu(c, 1).^2)
#     # c = corrcoef(x)
#     # s = -sum(sum(triu(c,1).^2))

# function scoreMean(x, crit)
#     # compute score function; larger is better
#     if size(x,1)<2
#         s = 0;       # score is meaningless with just one point
#         return s
#     end

#     if crit=="maximin"        # Maximize the minimum point-to-point difference
#         # xTransposed = convert{Array{Float64, p}, x'}
#         xTransposed = x'

#         kdtree = KDTree(xTransposed)
#         _, dist = knn(kdtree, xTransposed, 2, true)
#         distArray = vecvec_to_matrix(dist)
#         s1 = minimum(distArray[:, 2])
#         s2 = mean(distArray[:, 2])

#     end
#     return s1, s2

# end
