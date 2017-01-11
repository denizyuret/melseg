using Knet

# sample usage:
# m128 = MLP([3644,128,1])
# mlprun(data; model=m128, epochs=20)

# define a model type with weights and optimization params so we can
# use the Adam optimizer which works faster than SGD:

type MLP
    weights
    oparams
    function MLP(sizes; optimizer=Adam, winit=0.1, atype=Array{Float32})
        m = new(Any[],Any[])
        for i=2:length(sizes)
            w = convert(atype,winit*randn(sizes[i],sizes[i-1]))
            b = convert(atype,zeros(sizes[i],1))
            push!(m.weights, w)
            push!(m.oparams, optimizer(w))
            push!(m.weights, b)
            push!(m.oparams, optimizer(b))
        end
        return m
    end
end

# y = mlppred(model.weights, x)

function mlppred(w,x)
    for i=1:2:length(w)-2
        x = max(0, w[i]*x .+ w[i+1])
    end
    return w[end-1]*x .+ w[end]
end

# this is the logistic loss

mlploss(w,x,y) = mean(log(1 .+ exp(-y .* mlppred(w,x))))

mlpgrad = grad(mlploss)

# training loop, does one pass over data, modifies mlp in place

function train!(m::MLP, data)
    for (x,y) in data
        dw = mlpgrad(m.weights, x, y)
        for i in 1:length(m.weights)
            (m.weights[i],m.oparams[i]) = update!(m.weights[i], dw[i], m.oparams[i])
        end
    end
end

# returns logistic loss for model on data

function test(m::MLP, data)
    sumloss = numloss = 0
    for (x,y) in data
        sumloss += mlploss(m.weights, x, y)
        numloss += 1
    end
    sumloss / numloss
end

# returns classification accuracy for model on data

function acc(m::MLP, data)
    sumloss = numloss = 0
    for (x,y) in data
        z = mlppred(m.weights,x)
        sumloss += mean((z .* y) .> 0)
        numloss += 1
    end
    sumloss / numloss
end

# sample use script

function mlprun(data; epochs=10, sizes=[3644,128,1], model=MLP(sizes; atype = typeof(data[1][1][1])))
    println((:epoch,map(d->:accuracy,data)...,map(d->:loss,data)...))
    msg(e) = println((e,map(d->acc(model,d),data)...,map(d->test(model,d),data)...)); msg(0)
    for epoch = 1:epochs
        train!(model, data[1])
        msg(epoch)
    end
    return model
end

# missing in Knet:
Base.mean(a::KnetArray) = sum(a)/length(a)
Base.mean(a::AutoGrad.Rec) = sum(a)/length(a)

# to convert models:

function cpu2gpu(m::MLP)
    g = deepcopy(m)
    for i=1:length(g.weights)
        g.weights[i] = KnetArray(g.weights[i])
        g.oparams[i].fstm = KnetArray(g.oparams[i].fstm)
        g.oparams[i].scndm = KnetArray(g.oparams[i].scndm)
    end
    return g
end

function cpu2gpu(a)
    if isa(a,Array) && isbits(eltype(a))
        KnetArray(a)
    else
        map(cpu2gpu,a)
    end
end

# no-ref-ref experiments:
# bdata = trntst(pairdata(data); splt=((20000,20000),(1700,1700)))
# gdata = cpu2gpu(bdata)
# mlprun(gdata, epochs=100)
