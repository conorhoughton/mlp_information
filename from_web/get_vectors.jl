#https://github.com/denizyuret/Knet.jl/blob/master/examples/fashion-mnist/fashion-mnist.jl

module GetVectors

using Knet
using ArgParse
using Dates
include(Knet.dir("data","fashion-mnist.jl"))

"""
This example learns to classify images of fashion products(trousers, shirts, bags...) 
from the [Fashion-MNIST](https://github.com/zalandoresearch/fashion-mnist) dataset.  
There are 60000 training and 10000 test examples. Each input x 
consists of 784 pixels representing a 28x28 image. The pixel values are 
normalized to [0,1]. Each output y is converted to a ten-dimensional 
one-hot vector (a vector that has a single non-zero component) indicating 
the correct class (0-9) for a given image. 10 is used instead of 0.
Labels and descriptions are shown below.
    Label   Description
    1       T-shirt/top
    2       Trouser
    3       Pullover
    4       Dress
    5       Coat
    6       Sandal
    7       Shirt
    8       Sneaker
    9       Bag
    10      Ankle boot
You can run the demo using `julia fashion-mnist.jl` on the command line or
by first including `julia> include("fashion-mnist.jl")` and typing `julia> FashionMNIST.main()` 
at the Julia prompt.  Options can be used like `julia fashion-mnist.jl --epochs <3` 
or `julia> FashionMNIST.main("--epochs 3")`. Use `julia fashion-mnist.jl --help` 
for a list of options.  The dataset will be automatically downloaded.  
By default a softmax model will be trained for 10 epochs. You can also 
train a multi-layer perceptron by specifying one or more --hidden sizes. 
The accuracy for the training and test sets will be printed at every epoch 
and optimized parameters will be returned.
"""

function predict(w,x; pdrop=0.5)
    x = mat(x)
    for i=1:2:length(w)
        x = w[i]*dropout(x, pdrop) .+ w[i+1]
        if i<length(w)-1
            x = relu.(x) # max(0,x)
        end
    end
    return x
end


function saveStates(w,data,file,epoch;pdrop=0.5)

    for (batch,(x,y)) in enumerate(data)
        x = mat(x)
        for i=1:2:length(w)
            write(file,"batch $batch layer $i epoch $epoch\n")
            x = pdrop.*w[i]*x.+ w[i+1]
            for j=1:length(y)
                write(file,"$(convert(Int64,y[j])) $(x[:,j])\n")
            end
            if i<length(w)-1
                x = relu.(x) # max(0,x)
            end
        end
    end

end


loss(w,x,ygold;pdrop=0.5) = nll(predict(w,x;pdrop=pdrop), ygold)

lossgradient = grad(loss)

function train(w, dtrn; lr=.15, epochs=10, pdrop=0.5)
    for epoch=1:epochs
        for (x,y) in dtrn
            g = lossgradient(w, x, y; pdrop=pdrop)
            update!(w, g, lr=lr)
        end
    end
    return w
end

function weights(h...; atype=Array{Float32}, winit=0.1)
    w = Any[]
    x = 28*28
    for y in [h..., 10]
        push!(w, convert(atype, winit*randn(y,x)))
        push!(w, convert(atype, zeros(y, 1)))
        x = y
    end
    return w
end



mutable struct Performance
    cnt::Int64
    trn::Float64
    tst::Float64
end


function main(args="")
    s = ArgParseSettings()
    #s.description="fashion-mnist.jl (c) 2017 Adapted by Emre Unal based on Deniz Yuret's MNIST example https://github.com/denizyuret/Knet.jl/tree/master/examples/mnist-mlp/mlp.jl.\nMulti-layer perceptron model on the Fashion-MNIST dataset from https://github.com/zalandoresearch/fashion-mnist.\n Mildly adapted for drawing a performance graph Conor Houghton"
    s.exc_handler=ArgParse.debug_handler
    @add_arg_table s begin
        ("--seed"; arg_type=Int; default=-1; help="random number seed: use a nonnegative int for repeatable results")
        ("--batchsize"; arg_type=Int; default=100; help="minibatch size")
        ("--epochs"; arg_type=Int; default=10; help="number of epochs for training")
        ("--hidden"; nargs='*'; arg_type=Int; help="sizes of hidden layers, e.g. --hidden 128 64 for a net with two hidden layers")
        ("--lr"; arg_type=Float64; default=0.15; help="learning rate")
        ("--winit"; arg_type=Float64; default=0.1; help="w initialized with winit*randn()")
        ("--atype"; default=(gpu()>=0 ? "KnetArray{Float32}" : "Array{Float32}"); help="array type: Array for cpu, KnetArray for gpu")
        ("--dropout"; arg_type=Float64; default=0.5; help="Dropout probability.")
        ("--output"; arg_type=String; default="gv_"*Dates.format(now(),"yyyy-mm-dd-HH-MM-SS")*".txt"; help="saves the performance measures.")
        # These are to experiment with sparse arrays
        # ("--xtype"; help="input array type: defaults to atype")
        # ("--ytype"; help="output array type: defaults to atype")
    end
    isa(args, AbstractString) && (args=split(args))
    if in("--help", args) || in("-h", args)
        ArgParse.show_help(s; exit_when_done=false)
        return
    end
    o = parse_args(args, s; as_symbols=true)
    println("opts=",[(k,v) for (k,v) in o]...)
    o[:seed] > 0 && Knet.seed!(o[:seed])
    atype = eval(Meta.parse(o[:atype]))

    xtrn,ytrn,xtst,ytst = fmnist()
    global dtrn = minibatch(xtrn, ytrn, o[:batchsize]; xtype=atype)
    global dtst = minibatch(xtst, ytst, o[:batchsize]; xtype=atype)
    report(epoch)=println((:epoch,epoch,:trn,accuracy(w,dtrn,predict),:tst,accuracy(w,dtst,predict)))

    w = weights(o[:hidden]...; atype=atype, winit=o[:winit])

    outputFile=open(o[:output],"w")
    
    @time for epoch=0:o[:epochs]

        if epoch!=0
            train(w, dtrn; lr=o[:lr], epochs=1, pdrop=0.5)
        end
        report(epoch)
        saveStates(w,dtst,outputFile,epoch;pdrop=0.5)
        
    end

    close(outputFile)

    return w

end

# This allows both non-interactive (shell command) and interactive calls like:
# $ julia get_vectors.jl --epochs 10
# julia> GetVectors.main("--epochs 10")
PROGRAM_FILE == "get_vectors.jl" && main(ARGS)

end # module
