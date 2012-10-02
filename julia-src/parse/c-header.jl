#
#  Copyright (C) 01-10-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

#TODO start trying things starting with the types,

#Makes a stream with a string.
function stream_from_string(string::String)
  s = memio(length(string))
  write(s, string)
  seek(s,0) #Need to seek to start.
  return s
end
string_from_stream() = memio() #Which is a IOStream, which has a (todo name it

type ConvenientStream
  stream::IOStream
  line::String
end
ConvenientStream(stream::IOStream) = ConvenientStream(stream,"")
#Pass on @with requirement.
no_longer_with(cs::ConvenientStream) = no_longer_with(cs.stream)

#TODO counting newlines shouldn't be too hard..
function forward(cs::ConvenientStream, n::Integer)
  if n>length(cs.line)
    cs.line = readline(cs.stream)[n-length(cs.line):]
  else
    cs.line = cs.line[n+1:]
  end
  return nothing
end
readline(cs::ConvenientStream) = (cs.line = readline(cs.stream)) #!

#function tokenize(input::IOStream, white::String, stop::String,
function c_header_parse(in::IOStream)
#Could try not pre-tokenizing again.. ?
#global:
#  typedef name type (attach type to name)
#  #.. (ignore)
#type|global:
#  struct [name] { ...struct_body... };
#variables
#  starts with type, then list of possibly pre-set variables.
#function
#  type name(args){ ...body... }
#args
#  
#body:
#  variables|expressions
#expressions:
#  
#struct_body:
#  body but no setting and no functions.
#comments
#  //
#  /*enclosed*/
end

#Skip to the line containing the given object sequence.
function get_to_line_with{W}(in::ConvenientStream, with::W)
  line = in.line
  while true
    i,j = search(in.line, with)
    if i==0 && j==0
      readline(in)
    else #Found it.
      forward(in, j-1) #(in.line = line[j:])
      return nothing
    end
  end
end
#Skips comments, whitespace. TODO rename to skip_white or such
function line_handle(in::ConvenientStream)
  next_up(str) = begins_with(in.line, str)
  while true
    if isempty(in.line) || contains(" \t\n", in.line[1]) #Skip whitespace.
      forward(in, 1)
    elseif next_up("//") || next_up("#") #Skip whole lines.
      readline(in)
    elseif next_up("/*") #Skip to end of comment.
      get_to_line_with(in,"*/",)
    else #Not a comment or any such, return.
      return nothing
    end
  end
end

type TokFun
  name::Symbol
  args::Array{Any,1}
  ret_tp::Any
end

show(io, s::TokFun) = write(io,"$(s.name)$(s.args)::$(s.ret_tp)") #!

type TokVar
  name::Symbol
  tp::Any
end

type TokStruct
  name::Symbol
  members::Array{Any,1}
end

#type TokEnum #TODO

show(io,s::TokVar) = write(io, "$(s.name)::$(s.tp)") #!

type TokType
  symbols::Vector{Any}
  function TokType(tok_list) 
    ensymbol(str::String) = symbol(str)
    ensymbol(t) = t
    new(map(ensymbol, tok_list))
  end
end

type TokTypedef
  val
end
#TODO query the type for stuff.

toklist_to_type_arg(toklist) =
    TokVar(symbol(last(toklist)), TokType(butlast(toklist)))

#Tokenizes for C. 
function tokenize_for_c(in::ConvenientStream, what)
  list = {}
  args_list = {}
  j = 1
  while true #TODO start instead by parsing a type.
    line_handle(in)

    function forw()
      forward(in,j)
      j=1
    end
    function push_cur()
      str = in.line[1:j-1]
      ch = (j<= length(in.line) ? in.line[j] : '\0')
      forw()
      if str == "struct" && ch=='{' #TODO named structs
        forward(in,1)
        push(list, parse_struct(in))
      elseif length(str)>0
        push(list, str)
      end
    end
    next_up(chars...) = contains(chars, in.line[j])
   
    if j>length(in.line) || next_up(' ', '\t', '/') #Whitespace.
      push_cur()
      line_handle(in)
    elseif next_up('(')
      push_cur()
      line_handle(in)
      if in.line[1]=='*'
        error("Function types not yet supported.")
      end
      arg_list = tokenize_for_c(in, :funargs)
      return TokFun(symbol(last(list)), arg_list,
                    TokType(butlast(list)))
    elseif next_up(')') #Not in arguments and receiving ')'...
      assert( what == :funargs )
      push_cur()
      if !isempty(list) #TODO enforce no `,/*nothing*/)`
        push(args_list, toklist_to_type_arg(list))
      end
      line_handle(in)
      assert( in.line[1]==';' ) #Must be ';'-separated. # TODO { for more.
      return args_list
    elseif next_up('{')
      push_cur() #will also handle `struct`, if there.
    elseif next_up(',')
      assert( j>1 )
      assert( what == :funargs )
      push_cur()
      push(args_list, toklist_to_type_arg(list))
      list = {}
    elseif next_up(';')
      push_cur()
      assert( what!=:funargs ) #Arguments ended too early.
      return toklist_to_type_arg(list)
    elseif next_up('}')
      error("Found '}' that doesn't seem opened")
    end
    j += 1
  end
  return list
end

function parse_struct(in::ConvenientStream)
  list = {}
  line_handle(in)
  while in.line[1]!='}'
    push(list, tokenize_for_c(in, :struct))
    line_handle(in)
  end
  return TokStruct(:ignore, list)
end
function parse_union(in::ConvenientStream) #TODO
  list = {}
  line_handle(in)
  #TODO allow , ; and  = to define shit.
end

function parse_toplevel_1(in::ConvenientStream)
  line_handle(in)
  if begins_with(in.line, "typedef")
    forward(in, 7)
    push(list, TokTypeDef(tokenize_for_c(in, :typedef)))
  else
    push(list, tokenize_for_c(in, :top))
  end
end

function eof(stream::IOStream) #Hrmmm
  i = position(stream)
  seek_end(stream)
  if i == position(stream) #Terrible.
    return true
  end
  seek(i)
  return false
end

function parse_toplevel(in::ConvenientStream)
  list = {}
  while !eof(in.stream)
    push(list, parse_toplevel_1(in))
  end
  return list
end

parse_toplevel(in::IOStream) = parse_toplevel(ConvenientStream(in))
parse_toplevel(file::String) =
    @with stream = open(file, "r") parse_toplevel(stream)