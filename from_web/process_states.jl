

using ArgParse

struct State
    label::Int64
    stateV::Vector{Float64}
end

struct LabelDistance
    label::Int64
    d::Float64
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

    states=readStates(inputFile,epoch,layer)
    
    labels=[s.label for s in states]

    distance_matrix=distanceMatrix(states[1:5])

    nearests=Vector{Int64}[]

    compare_states(a)=a.d

    
    
    for i=1:5#length(states)
        this_nearests=[v.label for v in sort(distance_matrix[i,:],by=compare_states)]
        push!(nearests,this_nearests)
    end

    distance_matrix=nothing

end

main()
