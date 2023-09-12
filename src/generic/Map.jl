###############################################################################
#
#  Map.jl : Maps
#
###############################################################################

###############################################################################
#
#   CompositeMap
#
###############################################################################

domain(f::CompositeMap{D, C}) where {D, C} = domain(f.map1)::D
codomain(f::CompositeMap{D, C}) where {D, C} = codomain(f.map2)::C
map1(f::CompositeMap) = f.map1
map2(f::CompositeMap) = f.map2

function (f::CompositeMap{D, C})(a) where {D, C}
   return f.map2(f.map1(a))::elem_type(C)
end

function show_short(io::IO, M::CompositeMap)
   show_short(io, M.map1)
   println(io, "then")
   print(io, M.map2)
end

function show(io::IO, M::CompositeMap)
   println(io, "Composite map consisting of the following")
   println(io, "")
   show_short(io, M.map1)
   println(io, "then")
   show_short(io, M.map2)
end

################################################################################
#
#  IdentityMap
#
################################################################################

(f::IdentityMap)(a) = a

domain(f::IdentityMap) = f.domain
codomain(f::IdentityMap) = f.domain

function show(io::IO, M::IdentityMap)
   println(io, "Identity map with")
   println(io, "")
   println(io, "Domain:")
   println(io, "=======")
   print(io, domain(M))
end

function compose(f::AbstractAlgebra.Map(AbstractAlgebra.IdentityMap){D, D}, g::AbstractAlgebra.Map{D, C}) where {D, C}
   check_composable(f, g)
   return g
end

function compose(f::AbstractAlgebra.Map{D, C}, g::AbstractAlgebra.Map(AbstractAlgebra.IdentityMap){C, C}) where {D, C}
   check_composable(f, g)
   return f
end

function compose(f::AbstractAlgebra.Map(AbstractAlgebra.IdentityMap){D, D}, g::AbstractAlgebra.Map(AbstractAlgebra.IdentityMap){D, D}) where D
   check_composable(f, g)
   return g
end

Base.inv(f::AbstractAlgebra.Map(AbstractAlgebra.IdentityMap)) = f

################################################################################
#
#  FunctionalMap
#
################################################################################

domain(f::FunctionalMap) = f.domain
codomain(f::FunctionalMap) = f.codomain
image_fn(f::FunctionalMap) = f.image_fn

function (f::FunctionalMap{D, C})(a) where {D, C}
   parent(a) != domain(f) && throw(DomainError(f))
   return image_fn(f)(a)::elem_type(C)
end



function Base.show(io::IO, ::MIME"text/plain", M::FunctionalMap)
   io = pretty(io)
   println(io, "Map defined by a Julia function")
   println(io, Indent(), "from ", Lowercase(), domain(M))
   print(io, "to ", Lowercase(), codomain(M))
end

function Base.show(io::IO, M::FunctionalMap)
   io = pretty(io)
   if get(io, :supercompact, false)
      # no nested printing
      print(io, "Map")
   else
      # nested printing allowed, preferably supercompact
      print(io, "Map: ")
      print(IOContext(io, :supercompact => true), Lowercase(), domain(M), " -> ")
      print(IOContext(io, :supercompact => true), Lowercase(), codomain(M))
   end
end

################################################################################
#
#  FunctionalCompositeMap
#
################################################################################

domain(f::FunctionalCompositeMap) = domain(f.map1)
codomain(f::FunctionalCompositeMap) = codomain(f.map2)

# This is a device to prevent Julia trying to compute
# the types of a very long composition of closures
struct UntypedFunction <: Function
   fn::Function
end

function compose(f::UntypedFunction, g::UntypedFunction, d)
   return function(x)
      parent(x) != d && error("Element not in domain of map")
      return f.fn(g.fn(x))
   end
end

(f::UntypedFunction)(a) = f.fn(a)

function image_fn(f::FunctionalCompositeMap)
   if isdefined(f, :fn_cache)
      return f.fn_cache
   else
      f1 = image_fn(f.map1)
      f2 = image_fn(f.map2)
      d = domain(f)
      fn = compose(UntypedFunction(f2), UntypedFunction(f1), d)
      f.fn_cache = fn
      return fn
   end
end

map1(f::FunctionalCompositeMap) = f.map1
map2(f::FunctionalCompositeMap) = f.map2

function (f::FunctionalCompositeMap{D, C})(a) where {D, C}
   return image_fn(f)(a)::elem_type(C)
end

function show_short(io::IO, M::AbstractAlgebra.Map)
   println(IOContext(io, :compact => true), domain(M), " -> ", codomain(M))
end

function show_short(io::IO, M::FunctionalCompositeMap)
   show_short(io, M.map1)
   println(io, "then")
   print(io, M.map2)
end

function show(io::IO, M::FunctionalCompositeMap)
   println(io, "Composite map consisting of the following")
   println(io, "")
   show_short(io, M.map1)
   println(io, "then")
   show_short(io, M.map2)
end



