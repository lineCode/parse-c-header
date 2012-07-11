
(in-package :header-cffi)

(defun keep-parsing (s &key (max-n 1000) (nots nil))
  (print :-------------------) 
  (dotimes (n max-n (vector n nots))
    (let ((got (car (parse-c-body 
		     (remove #\Newline (c-like-tokenize s))))))
      (when got
	(print got)
	(print (to-cffi::cffi-code got)))
      (unless got
	(push n nots)))))

(let ((to-cffi::*string-conv* #'string-upcase))
  (with-input-from-string
      (s
     ;"__attribute__((visibility(\"default\"))) 
"void glLoadTransposeMatrixd( const GLdouble m[16] ); static const unsigned long long x;")
    (preprocessed-stream-cffi-apply s)))

(with-open-file (s "gl-e") 
  (keep-parsing s :max-n 3000))

  (preprocessed-stream-cffi-apply s))

(with-input-from-string (s "const int x;
double sqr(const double x,double y,double z[])
{ return x; }
#comment
int y; ")
  (preprocessed-stream-cffi-apply s))


(with-input-from-string (s "typedef struct ska {long int x;} ska;")
;  (cffi-code (car (parse-c-body (c-like-tokenize s)))))
  (preprocessed-stream-cffi-apply s))
