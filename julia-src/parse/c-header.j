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

type StringFromStream
  stream::IOStream
end

string_from_stream() = memio() #Which is a IOStream, which has a (todo name it

read_char(in::IOStream) = read(in,Char)

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
function get_to_line_with{W}(in::IOStream, with::W, first_line::String)
  line = first_line
  while true
    i,j = search(line, with)
    if i==0 && j==0
      line = readline(in)
    else #Found it.
      return ((i,j), line)
    end
  end
end
#Skips comments, whitespace. TODO probably want to eat it.
function line_handle(line::String, in::IOStream)
  next_up(str) = begins_with(line, str)
  while true
    n = 1
    while isempty(line)
      line = readline(in)
      n+=1
      if n > 256 
        return line
      end
    end
    if contains(" \t\n", line[1]) #Skip whitespace.
      line = line[2:]
    elseif next_up("//") || next_up("#") #Skip whole lines.
      line = readline(in)
    elseif next_up("/*") #Skip to end of comment.
      (i,j), line =get_to_line_with(in,"*/", line)
      line = line[j:]
    else #Not a comment or any such, return.
      return line
    end
  end
end

type TokType
  symbols::Vector{Symbol}
  function TokType(tok_list) 
    new(map(symbol, tok_list))
  end
end
#TODO query the type for stuff.

toklist_to_type_arg(toklist) =
    Expr(symbol("::"), {symbol(last(toklist)), TokType(butlast(toklist))},Any)

#Tokenizes for C.
function tokenize_for_c(line::String, in::IOStream, what)
  list = {}
  args_list = {}
  i,j= (1,1)
  while true
    function white_end()
      if i>j
        push(list, line[j:(i-1)])
      end
      line = line_handle(line[i:], in)
      i,j = (1,1)
    end
    if i >= length(line)
      white_end()
    end
    @case line[i] begin
      if ' ' | '\t' | '/'
        white_end()
      end
      if '('
        if i>j
          push(list, line[j:(i-1)])
        end
        arg_list = tokenize_for_c(line[i+1:],in, :args)
        return Expr(symbol(last(list)), arg_list, TokType(butlast(list)))
      end
      if ')' #Not in arguments and receiving ')'...
        assert( what == :args )
        push(list, line[j:(i-1)])
        push(args_list, toklist_to_type_arg(list))
        return args_list
      end
      if ','
        assert( j<i )
        assert( what == :args )
        push(list, line[j:(i-1)])
        push(args_list, toklist_to_type_arg(list))
        j= i+1
        list = {}
      end
      if ';'
        assert( what!=args ) #Arguments ended too early.
      end
    end
    i += 1
  end
  return list
end

function parse_type(line::String,in::IOStream)
  line = line_handle(line,in)
  if begins_with(line, "struct") #It is a struct type.
    return parse_struct(line[6:],in)
  end
#Some other type.
  line,list = tokenize_for_c(line,in)
  parse_type(list, false)
end
function parse_type(list, in_args::Bool)
  new_list = {{}}
  for i = 1:length(list)
    if !isa(list[i],Character)
      push(new_list[1], list[i])
    elseif list[i] == ','
      assert(in_args)
      push(new_list, {})
    elseif list[i] == '(' 
      name = list[i+1]
      assert( list[i+2] == ')' )
      assert( list[i+3] == '(' )
      return CFunType(name, CType(new_list[1]), parse_type(list[i+3:],true)) #TODO arg types.
    elseif list[i] == ')'
      assert( in_args )
      return map(CType, new_list)
    end
  end
  assert( length(new_list)==1 )
  return CType(new_list[1])
end

function parse_toplevel(in::IOStream)
  next_up(str) = begins_with(line, str)
  list = {}
  line = ""
  try
    while true
      line = line_handle(readline(in), in) #After this, has to be something.
#      push(list, @cond begin
#                   next_up("typedef") : parse_type(line[7:],in)
#                   next_up("struct")  : parse_struct(line[6:],in)
#                   default            : parse_var_or_fun(line,in)
#                 end)
    end
  catch thing
    #TODO catch difference end-of-stream with other stuff.
  end
  return list
end
