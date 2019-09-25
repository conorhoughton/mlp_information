

using ArgParse
    
function parseArgs()

    s = ArgParseSettings()
    s.exc_handler=ArgParse.debug_handler

    @add_arg_table s begin
        ("--input"; arg_type=String; required = true; help="input file name for table of prediction values")
        ("--epoch"; arg_type=Int; required = true; help="which epoch to process")
        ("--nt"; arg_type=Int;default=100;help="number of trials per image type to process")
    end

    o = parse_args(s)
    
    (o["input"],o["epoch"],o["nt"])

end



function readStates(inputFile::String,epoch,nt::Int64,ns::Int64)

    p=zeros(Float64,ns,ns)
    
    toggleRead=false
    
    labelCount=Dict{Int64,Int64}()

    open(inputFile,"r") do file
        
        for line = eachline(file)

            if line[1]=='b'
                if parse(Int64,split(line," ")[4])==epoch
                    toggleRead=true
                else
                    toggleRead=false
                end
            elseif toggleRead

                values=parse.(Int64,split(line," "))
                
                label=values[1]

                count=get!(labelCount,label,0)

                if count<nt
                    p[label,values[2]]+=1.0
                    labelCount[label]+=1
                end

            end
        end
    end
    
    total=sum(p)
    p=p./total
    println(sum(p))
    p


end


function main()

    (inputFile,epoch,nt)=parseArgs()

    ns=10

    p=readStates(inputFile,epoch,nt,ns)

    println(typeof(p))
    
    println(sum([p[i,i] for i in 1:10]))


    
end

main()
   
