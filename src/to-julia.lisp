;;
;;  Copyright (C) 05-08-2012 Jasper den Ouden.
;;
;;  This is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published
;;  by the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;

(defpackage :to-julia
  (:use :common-lisp :alexandria :j-string-utils
	:parse-c-header :external-program)
  (:export to-julia julia-type *string-conv*)
  (:documentation "Makes julia source files that FFI C functions, based on a
 header. The code uses get_c.j"))

(in-package :to-julia)

(defvar *string-conv* #'string-rev-case
  "Here you can provide a function to handle how to change names.
 May return either a symbol or a string.")

(defun string-conv(string)
  "Turns 'symbols' of C into ones for Julia"
  (assert (stringp string))
  (string-case string
    ("type"  "_type") ;Forbidden strings. 
    ("end"   "_end")  ; ... wish Julia got out of the lisp-closet.
    ("begin" "_begin") ("while" "_while") ("for"   "_for")
    ("function" "_function")
    (t       (funcall *string-conv* string))))

(defun julia-type (type)
  (case (car type)
    ((:const :static :signed)
     (julia-type (cdr type)))
    (:void  "Void")
    (:ptr   "Ptr")
    (:char  "Uint8")
    (:short "Int16") (:int   "Int32") 
    (:float "Float32") (:double "Float64")
    (:long
     (case (cadr type) 
       (:int "Int64") (:double "Float64") ;long-double ok?
       (t "Int64"))) ;Incl. long-long
    (:unsigned
     (case (cadr type) 
       (:char   "Uint8")    (:short "Uint16")
       (:int    "Uint32")   (:long  "Uint64")
       (t      (error ""))))
    (t
     (car type))))

;TODO telling it to ignore stuff.
(defun to-julia (code &key dlopen-lib stream)
  "Produce code for foreign-interfacing the given stuff."
  (unless code (return-from to-julia))
  (assert (listp code))
  (destructuring-bind (name &rest args) code
    (case name
      (:typedef
  ;TODO Julia doesn't support structs yet, so don't produce 'bad stuff'
       (destructuring-bind (name &rest type) args
	 (format stream "typealias ~a ~a~%" name (julia-type type))))
      (:function ;Currently _just_ functions.
       (destructuring-bind (name (&key type attr &allow-other-keys) args
				 &rest more) args
	 (declare (ignore more attr))
	 (format stream "@get_c_fun ~a ~a ~a(~{~a~^,~})::~a~%" 
		 dlopen-lib (string-conv name) name
		 (mapcar (lambda (a) 
			   (destructuring-bind (var-indicator var &rest type)
			       a
			     (assert (eql var-indicator :var))
			     (format nil "~a::~a" (string-conv var) 
				     (julia-type type))))
			 args)
		 (julia-type type))))
      (:define ;It is dumb, doesn't look if it is actually compatible.
       (let*((set-to (reduce #'concat (cdr args)))
	     (cut    (min (or (search "//" set-to) (length set-to))
			  (or (search "/*" set-to) (length set-to))))
	     (val    (subseq set-to 0 cut)))
	 (when (> (length (remove-if (rcurry #'find '(#\Space #\Tab)) val)) 0)
	   (format stream "const ~a = ~a~%" (car args) val)))))))


