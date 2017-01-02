using JSON, JLD

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
