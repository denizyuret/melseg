using JSON, JLD

function loaddata()
    data  = Any[]
    files = readdir(".")
    for f in files
        ismatch(r"^\w+\.json$", f) || continue
        println(f)
        dict = JSON.parsefile(f)
        for v in values(dict)
            isa(v,Void) && continue
            for i=1:length(v)
                v[i] = convert(Array{Float32},v[i])
            end
        end
        push!(data, dict)
    end
    return data
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
