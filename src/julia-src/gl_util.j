#  Jasper den Ouden 02-08-2012
# Placed in public domain.

#Handy stuff to make use of Julia features.
#Probably best to stay similar to cl-opengl.

#Overloading stuff
glvertex(i::Integer,j::Integer) = glvertex2i(i,j)
glvertex(i::Integer,j::Integer,k::Integer) = glvertex3i(i,j,k)
glvertex(i::Integer,j::Integer,k::Integer,l::Integer) = glvertex3i(i,j,k,l)

glvertex(x::Number,y::Number) = glvertex2d(x,y)
glvertex(x::Number,y::Number,z::Number) = glvertex3d(x,y,z)
glvertex(x::Number,y::Number,z::Number,w::Number) = glvertex4d(x,y,z,w)

#function glvertex(v::(Number,Number)) #Addition not defined on these either
#  x,y = v
#  glvertex(x,y)
#end
function glvertex{T}(v::Array{T,1})
  if length(v)==3
    return glvertex(v[1],v[2],v[3])
  end
  if length(v)==2
    return glvertex(v[1],v[2])
  end
  if length(v)==4
    return glvertex(v[1],v[2],v[3],v[4])
  end
end

glnormal(x::Number,y::Number,z::Number) = glnormal3d(x,y,z)
#glnormal(i::Integer,j::Integer,k::Integer) = glnormal3b(i,j,k)

glcolor(r::Number,g::Number,b::Number) = glcolor3f(r,g,b)
glcolor(r::Number,g::Number,b::Number,a::Number) = glcolor4f(r,g,b,a)

glcolorb(r::Integer,g::Integer,b::Integer) = glcolor3b(r,g,b)
glcolorb(r::Integer,g::Integer,b::Integer,a::Integer) = glcolor4b(r,g,b,a)

glscale(x::Number,y::Number,z::Number) = glscaled(x,y,z)
glscale(x::Number,y::Number) = glscaled(x,y,1)
glscale(s::Number) = glscaled(s,s,s)

gltranslate(x::Number,y::Number,z::Number) = gltranslated(x,y,z)

glscale(x::Number,y::Number) = glscaled(x,y,1)
gltranslate(x::Number,y::Number) = gltranslated(x,y,0)
glrotate(angle::Number, nx::Number,ny::Number,nz::Number) =
    glrotated(angle, nx,ny,nz)
glrotate(angle::Number) = glrotated(angle, 0,0,1)

#The whole `begin` ... `end` structures are rather bad for the savings from the 
# macros below.. 

#NOTE: if you `return` or something in the middle it won't end of course!
# (no `cl:unwind-protect`)

#Begin-end macro.
macro with_primitive (primitive, code)
  quote glbegin($primitive)
    ret = $code #remember what to return.
    glend() 
    ret #Note: in CL i'd use `prog1` to avoid the local variable.
  end
end
#Pushing and popping matrix.
macro with_pushed_matrix(code)
  quote
    glpushmatrix()
    ret = $code
    glpopmatrix()
    ret
  end
end

#More functions
function unit_frame()
  glloadidentity()
  gltranslate(-1,-1)
  glscale(2)
end

#Project to the given range.
function frame_to(fx::Number,fy::Number,tx::Number,ty::Number)
  gltranslate(fx,fy)
  assert( fx!=tx && fy!=ty, "There might be a division by zero here.." )
  glscale(1/(tx-fx),1/(ty-fy))
end
frame_to(fr::Vector, to::Vector) = frame_to(fr[1],fr[2], to[1],to[2])
function frame_to(range::(Number,Number,Number,Number))
  fx,fy,tx,ty = range
  frame_to(fx,fy,tx,ty)
end

#TODO frame_from?
function frame_from(fx::Number,fy::Number,tx::Number,ty::Number)
  gltranslate(fx,fy)
  glscale(tx-fx, ty-fy)
end
frame_from(fr::Vector, to::Vector) = frame_from(fr[1],fr[2], to[1],to[2])
function frame_from(range::(Number,Number,Number,Number))
  fx,fy,tx,ty = range
  frame_from(fx,fy,tx,ty)
end

#Rectangle vertices (in QUADS, LINE_LOOP-able style)
function quad_vertices(fx::Number,fy::Number,tx::Number,ty::Number)
  glvertex(fx,fy)
  glvertex(fx,ty)
  glvertex(tx,ty)
  glvertex(tx,fy)
end
function quad_vertices(range::(Number,Number,Number,Number))
  fx,fy,tx,ty = range
  quad_vertices(fx,fy,tx,ty)
end
quad_vertices(fr::Vector, to::Vector) = 
    quad_vertices(fr[1],fr[2], to[1],to[2])

vertices_around(x::Number,y::Number, r::Number) = 
    quad_vertices(x-r,y-r, x+r, y+r)

vertices_around(pos::Vector, r::Number) = vertices_around(pos[1],pos[2],r)
