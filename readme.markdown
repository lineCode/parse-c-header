
# Parse C headers

I wrote this Common Lisp code to parse *preprocessed* C headers and
use that data to generate cffi code(inside macro). (I have had trouble 
using other peoples' code like the 'groveller') 

There is also a [Julia](http://julialang.org/) code outputter. 

The current status is 'maybe it works', at best.

### Considerations
Using a macro to use the output directly has the disadvantage that
it has to read the header each time, and there would be the worry with
some sort of change on the output making things incompatible.
It is probably better to 'memoize' and produce a source code file,
that uses some apropriate macros to place the data 'as it is' there.

However, it is worse if the initially automatically generated file would
become something people have to look at/'maintain'. Maybe any needed modifications
should be automatic too, and the modificator is the thing to maintain.

`#defines` matter, for instance all of opengls primitives are `#define`s
currently it just dumbly takes everything with `#define` before it. And for opengl
there are (currently) duplicates from different branches. IMO this all seems much 
more complicated than it should be.(which could be my fault..)

## Dependencies

Uses some stuff like [Alexandria](http://common-lisp.net/project/alexandria/), 
and some of my string stuff from [j-basic](https://github.com/o-jasper/j-basic). 
(notably `j-string-utils:tokenize`), as usual.

`:to-cffi` needs to make symbols in [CFFI](http://common-lisp.net/project/cffi/)

`:header-cffi` helps using the program to preprocess, as such it uses
[external-program](http://common-lisp.net/project/external-program/).

### TODO(maybe)

* Make the julia one work better, give up on structs properly for now. 
  (not supported yet)

* I using Julia with opengl in another project, that code should be here.
  (current stuff is crap, but the other stuff not ready either)

* Improve the status of the code, testing it on stuff in /usr/include/

* Convert the parser to Julia, so the macros can do it directly.

* For lisp, allow generating of files as above.(Put a comment in
  dissuading people from editing it directly)

## Copyright
Everything is under GPLv3, license included under `doc/`

## Author

Jasper den Ouden
