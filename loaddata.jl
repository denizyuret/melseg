using JSON, JLD, DSP

# Load and normalize data within [0,1].

function loaddata(fmin=5800, fmax=7300)
    data  = Any[]
    files = readdir(".")
    for f in files
        ismatch(r"^\w+\.json$", f) || continue
        println(f)
        dict = JSON.parsefile(f)
        for (k,v) in dict
            if isa(v,Void)
                dict[k] = Any[]
            else
                for i=1:length(v)
                    v[i] = (convert(Array{Float32},v[i]) - fmin) ./ (fmax-fmin)
                end
            end
        end
        push!(data, dict)
    end
    return data
end

# Save Julia version:
# JLD.save("groupedMelSegData.jld","data",loaddata())

# subsample using DSP.resample (takes long)
function subsample(data, rate)
    sdata = Any[]
    for dict in data
        sdict = Dict()
        for (k,v) in dict
            svecs = Any[]
            for a in v
                push!(svecs, resample(a, rate))
            end
            sdict[k] = svecs
        end
        push!(sdata, sdict)
    end
    return sdata
end

# Generate positive and negative examples: Returns a pair of matrices,
# one for true one for false examples.  The columns of matrices
# contain the pair concatenated.
function pairdata(data)
    tout = Float32[]
    fout = Float32[]
    for d in data
        t = vcat(d["RefSegsTrue"], d["PerSegsTrue"])
        for i=1:length(t)-1
            for j=i+1:length(t)
                append!(tout, t[i])
                append!(tout, t[j])
            end
        end
        f = d["PerSegsFalse"]
        for i=1:length(t)
            for j=1:length(f)
                append!(fout, t[i])
                append!(fout, f[j])
            end
        end
    end
    rows = 2*length(data[1]["RefSegsTrue"][1])
    cols = div(length(tout),rows)
    tout = reshape(tout, (rows,cols))
    cols = div(length(fout),rows)
    fout = reshape(fout, (rows,cols))
    return (tout, fout)
end


# Split the pair data into a balanced train, dev and test set with a given minibatch size.
function trntst(pdata; batch=100, splt=((50000,50000),(5000,5000),(5000,5000)))
    (xt,xf) = pdata
    (nd,nt) = size(xt)
    (nd,nf) = size(xf)
    rt = randperm(nt)
    rf = randperm(nf)
    nt = nf = 0
    bdata = Any[]
    for (t,f) in splt
        x = hcat(xt[:,rt[nt+1:nt+t]], xf[:,rf[nf+1:nf+f]])
        y = hcat(ones(Float32,1,t), -ones(Float32,1,f))
        nt += t; nf += f
        r = randperm(t+f)
        batches = Any[]
        for i=1:batch:length(r)
            xbatch = x[:,r[i:i+batch-1]]
            ybatch = y[:,r[i:i+batch-1]]
            push!(batches, (xbatch, ybatch))
        end
        push!(bdata, batches)
    end
    return bdata
end

# To load and save KnetArrays:
import JLD: writeas, readas
type _KnetArray; a::Array; end
writeas(c::KnetArray) = _KnetArray(Array(c))
readas(d::_KnetArray) = KnetArray(d.a)

# bdata = trntst(pairdata(loaddata()))

# function mat32(x)
#     isa(x,Void) && return x
#     cols = length(x)
#     rows = length(x[1])
#     m = Array(Float32, rows, cols)
#     for i = 1:length(x)
#         m[:,i] = x[i]
#     end
#     return m
# end
