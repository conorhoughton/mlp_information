
using Pkg;
using Knet
using Statistics

function nonlinearity(x)
    #    max(0,x)
    tanh(x)
end



function predict(w,x)
    for i=1:2:length(w)-2
        x = nonlinearity.(w[i]*mat(x) .+ w[i+1])
    end
    return w[end-1]*mat(x) .+ w[end]
end

function loss(w,x,label)

    y = predict(w,x)
    sum(label.*(-y.+ log.(sum(exp.(y),dims=1))))/size(y,2)

end

lossgradient = grad(loss)

function makeTrain(lr)
    function train(w,data)
        for (x,y) in data
            dw=lossgradient(w,x,y)
            for i in 1:length(w)

                w[i]-=lr*dw[i]
            end
        end
    end
end

function accuracy(w, data)
    ncorrect = ninstance = 0
    for (x, label) in data
        y = predict(w,x)
        ncorrect += sum([c[1] for c in argmax(label,dims=1)]'.==[c[1] for c in argmax(y,dims=1)]')
        ninstance += size(y,2)
    end
    return ncorrect/ninstance
end

include(Knet.dir("/home/cscjh/git/mlp_information/mnist-fashion","/home/cscjh/git/mlp_information/mnist.jl"))

xtrn,ytrn,xtst,ytst = mnist()

function convert_to_vector(x,y)
    new_y=zeros(Int64,(10,size(x)[4]))
    for (i,this_y) in enumerate(y)
        new_y[this_y,i]=1
    end
    new_y
end

ytst=convert_to_vector(xtst,ytst)
ytrn=convert_to_vector(xtrn,ytrn)

dtst  =minibatch(xtst,ytst,100;xtype=Array{Float32})
dtrn = minibatch(xtrn,ytrn,100;xtype=Array{Float32})

layers=[10,10]

pushfirst!(layers,784)
push!(layers,10)

w=[]
for i in 1:length(layers)-1
    push!(w,0.1*rand(layers[i+1],layers[i]))
    push!(w,zeros(layers[i+1],1))
end

w=map(Array{Float32},w)

(x,y)=first(dtrn)

println(accuracy(w,dtst))

lr=0.2
train=makeTrain(lr)

println(gpu())

for i=1:30
    train(w, dtrn)
    println(i," ",accuracy(w,dtst))
end

