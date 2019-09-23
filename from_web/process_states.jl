

using ArgParse

struct State
    label::Int64
    stateV::Vector{Float64}
end

struct LabelDistance
    label::Int64
    d::Float64
end


function calcInfor(labels::Vector{Int64},nearests::Vector{Vector{Int64}},h::Int64,ns::Int64)
    
    information=0.0::Float64

    for (i,nearest) in enumerate(nearests)
        c=1.0::Float64
        this_label=labels[i]
        for i=2:h
            if labels[nearest[i]]==this_label
                c+=1.0
            end
        end
        information+=log2(ns*c/h)
    end

    information/length(nearests)

end


function readStates(inputFile::String,epoch,layer,nt::Int64)
        
    toggleRead=false
    
    labelCount=Dict{Int64,Int64}()

    states=State[]
    
    open(inputFile,"r") do file
        for line = eachline(file)

            if line[1]=='b'
                if parse(Int64,split(line," ")[4])==layer && parse(Int64,split(line," ")[6])==epoch
                    toggleRead=true
                else
                    toggleRead=false
                end
            elseif toggleRead
                label=parse(Int64,split(line,"[")[1])

                count=get!(labelCount,label,0)

                if count<nt
                    lineV=split(split(replace(line,"]"=>""),"[")[2],",")
                    stateV=[parse(Float64,x) for x in lineV]
                    push!(states,State(label,stateV))
                    labelCount[label]+=1
                end

            end
        end
    end

    states

end


function readStates(inputFile::String,epoch,layer)
        
    toggleRead=false
    
    states=State[]
    
    open(inputFile,"r") do file
        for line = eachline(file)

            if line[1]=='b'
                if parse(Int64,split(line," ")[4])==layer && parse(Int64,split(line," ")[6])==epoch
                    toggleRead=true
                else
                    toggleRead=false
                end
            elseif toggleRead
                label=parse(Int64,split(line,"[")[1])
                lineV=split(split(replace(line,"]"=>""),"[")[2],",")
                stateV=[parse(Float64,x) for x in lineV]

                push!(states,State(label,stateV))

            end
        end
    end

    states

end


function distanceMatrix(states::Vector{State})

    function d(v::Vector{Float64},w::Vector{Float64})
        sum(abs.(v-w))
    end
    
    n=length(states)

    distances=Array{LabelDistance,2}(undef,n,n)

    for i=1:n
        distances[i,i]=LabelDistance(i,0.0)
    end
    
    for i=1:n
        for j=i+1:n
            distances[i,j]=LabelDistance(j,d(states[i].stateV,states[j].stateV))
            distances[j,i]=LabelDistance(i,distances[i,j].d)
        end
    end

    distances

end

    
function parseArgs()

    s = ArgParseSettings()
    s.exc_handler=ArgParse.debug_handler

    @add_arg_table s begin
        ("--input"; arg_type=String; required = true; help="input file name for table of state values")
        ("--epoch"; arg_type=Int; required = true; help="which epoch to process")
        ("--layer"; arg_type=Int; required = true; help="which layer to process")
    end

    o = parse_args(s)
    
    (o["input"],o["epoch"],o["layer"])

end


function main()

    (inputFile,epoch,layer)=parseArgs()

    nt=15

    states=readStates(inputFile,epoch,layer,nt)

    labels=[s.label for s in states]

    distance_matrix=distanceMatrix(states)

    nearests=Vector{Int64}[]

    compare_states(a)=a.d
    
    for i=1:length(states)
        this_nearests=[v.label for v in sort(distance_matrix[i,:],by=compare_states)]
        push!(nearests,this_nearests)
    end

    distance_matrix=nothing

    h=15
    ns=10

    information=calcInfor(labels,nearests,h,ns)

    println(information)

end

main()
