export @ring, deg, monoms, exponent, matrixof, prodvec, prodset

import DynamicPolynomials: maxdegree, monomials
import LinearAlgebra: norm

function buildpolvar(::Type{PV}, arg, var) where PV
    :($(esc(arg)) = $var)
end

"""
```
@ring args...
```
Defines the arguments as variables and output their array.

Example
-------
```
X = @ring x1 x2
```
"""
macro ring(args...)
    X = DynamicPolynomials.PolyVar{true}[DynamicPolynomials.PolyVar{true}(string(arg)) for arg in args]
    V = [buildpolvar(PolyVar{true}, args[i], X[i]) for i in 1:length(X)]
    push!(V, :(TMP = $X) )
    Base.reduce((x,y) -> :($x; $y), V; init = :() )
end

#----------------------------------------------------------------------
"""
```
deg(p:Polynomial) -> Int64
```
Degree of a polynomial
"""
function deg(p::Polynomial{B,T}) where {B,T}
    maxdegree(p.x)
end

#----------------------------------------------------------------------
function deg(t::Term{B,T})  where {B,T}
    deg(t.x)
end
#----------------------------------------------------------------------
function deg(m::Monomial{C}) where C
    sum(m.z)
end
#----------------------------------------------------------------------
function deg(v::PolyVar{T}) where T
    1
end
#----------------------------------------------------------------------
function MultivariatePolynomials.variables(m::Monomial{C}) where C
    m.vars
end
#----------------------------------------------------------------------
function coeff(t::Term{B,T}) where {B,T}
    exponent(t.α)
end
#----------------------------------------------------------------------
function Base.one(::Type{Monomial{true}})
    Monomial{true}()
end

#----------------------------------------------------------------------
"""
```
exponent(m::Monomial) -> Array{Int64,1}
```
Get the exponent of a monomial as an array of Int64
"""
function Base.exponent(m::Monomial)
    return m.z
end

function Base.exponent(t::Term{B,T}) where {B,T}
    return t.x.z
end

# function DynamicPolynomials.monomial(m::Monomial)
#     return m
# end

# function DynamicPolynomials.monomial(t::Term{B,T}) where {B,T}
#     return t.x
# end
#----------------------------------------------------------------------
"""
```
 inv(m :: Monomial{true})
```
 return the inverse monomial with opposite exponents.
"""
function Base.inv(m:: Monomial{true})
    Monomial(m.vars,-m.z)
end

function Base.inv(v:: PolyVar{true})
    inv(Monomial(v))
end

function inv!(m:: Monomial{true})
    m.z=-m.z
end
#----------------------------------------------------------------------
function isprimal(m::Monomial{true})
    return !any(t->t<0, m.z)
end
#-----------------------------------------------------------------------
"""
```
monoms(V, d::Int64) -> Vector{Monomial}
monoms(V, rg::UnitRangeInt64) -> Vector{Monomial}
```
List of all monomials in the variables V up to degree d of from degree d1 to d2,
ordered by increasing degree.
"""
function monoms(V::Vector{PolyVar{true}}, rg::UnitRange{Int64})
    L = DynamicPolynomials.Monomial{true}[]
    for i in rg
        append!(L, DynamicPolynomials.monomials(V,i))
    end
    L
end

#-----------------------------------------------------------------------
"""
```
monoms(V, d::Int64) -> Vector{Monomial}
```
List of all monomials in the variables V up to degree d of from degree d1 to d2,
ordered by increasing degree.
"""
function monoms(V::Vector{PolyVar{true}}, d ::Int64)
    if (d>0)
        monoms(V,0:d)
    else
        L = monoms(V, 0:-d)
        for i in 1:length(L)
            inv!(L[i])
        end
        L
    end
end

#-----------------------------------------------------------------------
"""
Evaluate a polynomial p at a point x;

## Example
```
julia> X = @ring x1 x2;

julia> p = x1^2+x1*x2;

julia> p([1.0,0.5])
1.5
```
""" 
function (p::Polynomial{B,T})(x::AbstractVector, X=variables(p)) where {B,T}
    return p([X[i]=>x[i] for i in 1:length(x)]...)
    # r = zero(x[1]);
    # for m in p
    #    t=m.α
    #    for i in 1:length(m.x.z)
    #    	 t*=x[i]^m.x.z[i]
    #    end
    #    r+=t
    # end
    # r
end

#----------------------------------------------------------------------
function LinearAlgebra.norm(p::Polynomial{B,T}, x::Float64) where {B,T}
    if (x == Inf)
        r = - Inf
        for t in p
            r = max(r, abs(t.α))
        end
    else
        r = Inf
        for t in p
            r = min(r, abs(t.α))
        end
    end
    r
end

function LinearAlgebra.norm(pol::Polynomial{B,T}, p::Int64=2) where {B,T}
    r=sum(abs(t.α)^p for t in pol)
    exp(log(r)/p)
end

#----------------------------------------------------------------------
"""
 Coefficient matrix of the polynomials in P with respect to the monomial vector L
"""
function matrixof(P::Vector{Polynomial{B,C}}, L ) where {B,C}

    M = fill(zero(C), length(P), length(L))
    idx = Dict{Monomial{true},Int64}()
    for i in 1:length(L)
        idx[L[i]] = i
    end

    for i in 1:length(P)
        for t in P[i]
            j = get(idx,monomial(t),0)
            if j!=0 M[i,j]=coefficient(t) end
        end
    end
    M
end

"""
 Product-wise vector of X by Y ordered by row: [x1*y1, x1*y2, ..., x2*y1, ....] 
"""
function prodvec(X, Y)
    res = typeof(X[1])[]
    [x*y for x in X for y in Y]
end

"""
 Product-wise vector of X by Y ordered by row with no repetition: 
    if xi*yj appears as xi'*yj' with i'<i or i'=i and j'<j it is not inserted.
"""
function prodset(X, Y)
    res = typeof(X[1])[]
    for x in X
        for y in Y
            m = x*y
            if !in(m,res) push!(res, m) end
        end
    end
    res
end
