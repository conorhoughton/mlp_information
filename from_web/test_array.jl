
struct Foo
    a::Int64
    b::Int64
end

Foo()=Foo(1,2)

pV=Vector{Foo}(undef,3)
fill!(pV,Foo())



for p in pV
    println(p.a," ",p.b)
end
