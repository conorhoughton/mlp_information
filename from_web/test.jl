#https://github.com/denizyuret/Knet.jl/blob/master/examples/fashion-mnist/fashion-mnist.jl

using Knet
#using ArgParse


#module FashionMNIST



function loss(w,x,label)

    w*x

end

#loss(w,x,ygold;pdrop=0) = nll(predict(w,x;pdrop=pdrop), ygold)

lossgradient = grad(loss)

#end
