using JSON, JLD, DSP

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

# JLD.save("groupedMelSegData.jld","data",loaddata())

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

function pairdata(data)
    for d in data
        t = vcat(d["RefSegsTrue"], d["PerSegsTrue"])
        for i=1:length(t)-1
            for j=i+1:length(t)
                
            end
        end
        f = d["PerSegsFalse"]
        for i=1:length(t)
            for j=1:length(f)

            end
        end
        
    end
end

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
