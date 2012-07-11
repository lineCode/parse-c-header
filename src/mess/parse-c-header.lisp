
(in-package :parse-c-header)

(c-like-tokenize "252  534 (34,53)  536e; 4 ")
(c-like-tokenize "abvds  twg sgs (gs g) sg sg fsg")

(defun keep-parsing (s &key (max-n 1000))
  (print :-------------------) 
  (do ((n 0 (+ n 1)))
      ((or (not(print (parse-c-body (c-like-tokenize s)))) (> n max-n))
       n)))

(setf *default-pathname-defaults* 
      #p"/home/jasper/proj/common-lisp/starts/parse-c-header/")

(with-open-file (s "gl-e") (keep-parsing s))

(with-input-from-string (s "typedef enum {a=5,b,c,d,e=4} ska;")
  (parse-c-body (c-like-tokenize s)))

(with-input-from-string (s "typedef struct b {int ska} a;")
  (parse-c-body (c-like-tokenize s)))


(with-input-from-string (s "__attribute__((visibility(\"default\"))) void glClearIndex(A a,const B b,const C c);")
  (parse-c-body (c-like-tokenize s)))

(with-input-from-string (s "int x;
typedef struct { int x;
} Ska;
typedef unsigned int Ska;

enum{ a,b,c,d=4 };
int x;int y;
double sqr(double x,double y,double z)
{ return x; };
const int x;")
  (keep-parsing s))


(with-input-from-string (s "double sqr(double x,double y,double z)
{ return x; }
#comment
int y; //comment")
  ;(parse-c-body 
  (c-like-tokenize s)))
