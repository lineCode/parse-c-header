;;
;;  Copyright (C) 05-08-2012 Jasper den Ouden.
;;
;;  This is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published
;;  by the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;

(defpackage :to-cffi
  (:use :common-lisp :j-string-utils :cffi)
  (:export to-cffi cffi-type *string-conv*)
  (:documentation "Take input as from parse-c-header and turn it into cffi
 code."))

(in-package :to-cffi)

(defvar *string-conv* #'string-rev-case
  "Here you can provide a function to handle how to change names.
 May return either a symbol or a string.")

(defun string-conv(string)
  "Turns 'symbols' of C into ones in CL"
  (assert (stringp string))
  (let ((ret (funcall *string-conv* string)))
    (typecase ret
      (symbol ret)
      (string (intern ret))
      (t      (error "TODO")))))

(defun cffi-type (type)
  "Turn a type into cffi representation."
  (typecase (car type)
    (null
     nil)
    (symbol
     (assert (keywordp (car type)) nil "~a ~a" (car type) 
	     (symbol-package (car type)))
     (case (car type)
       ((:const :static :signed)
	(cffi-type (cdr type)))
       ((:void :char :short :int :float :double :ptr)
	(cons (car type) (cffi-type (cdr type))))
       (:long
	(cons (case (cadr type) 
		(:int :long-int) (:double :long-double) (:long :long-long)
		(t :long))
	      (cffi-type 
	       (nthcdr (case (cadr type) ((:int :double :long) 2) (t 1))
		       type))))
       (:unsigned
	(cons (case (cadr type) 
		(:char   :unsigned-char)    (:short :unsigned-short)
		(:int    :unsigned-int)
		(:long   (case (caddr type)
			   (:long :unsigned-long-long) 
			   (t     :unsigned-long)))
		(t      (error "")))
	      (cffi-type 
	       (nthcdr (case (cadr type) 
			 ((:char :short :int) 2) 
			 (:long               (if (eql (caddr type) :long)
						  2 1))
			 (t                   (error "")))
		       type))))
       (t
	(error "Unidentified keyword left by `parse-c-body ~a`" (car type)))))
    (list
     `((:todo ,@(car type)) ,@(cffi-type (cdr type))))
    (string
     (cons (string-conv (car type)) (cffi-type (cdr type))))))

(defun cffi-typevar (typevar)
  (destructuring-bind (var-indicator var &rest type) typevar
    (assert (eql var-indicator :var))
    `(,(string-conv var)
       ,(cffi-type type))))

(defun cffi-struct-code (elements)
  (mapcar (lambda (el)
	    (assert (listp el))
	    (when el
	      (destructuring-bind (var name &rest type) el
		(assert (eql var :var))
		`(,(string-conv name) ,@(cffi-type type)))))
	  (remove #\Newline elements)))

(defun to-cffi (code)
  "Generates cffi code based on `parse-c-body` code."
  (unless code (return-from to-cffi))
  (assert (listp code))
  (destructuring-bind (name &rest args) code
    (case name
      (:var
       (destructuring-bind (var-name &rest type) args
	 (assert (listp type))
	 `(defcvar (,var-name 
		    ,(if (eql (car type) :const)
			 (intern (format nil "+~a+" (string-conv var-name)))
			 (string-conv var-name)))
	      ,@(when (eql (car type) :const) '(:read-only twe))
	    ,(cffi-type type))))
      (:function
       (destructuring-bind (name (&key type attr &allow-other-keys) args
				 &rest more) args
	 (declare (ignore more attr))
	 `(defcfun (,name ,(string-conv name))
	      ,(cffi-type type) ;Return type.
	    ,@(mapcar #'cffi-typevar args))))
      (:typedef
       (destructuring-bind (name &rest type) args
	 (cond ((listp (car type))
		(destructuring-bind (what &rest rest) (car type)
		  (assert (case what ((:struct :enum) t)))
		  (let ((rest (remove #\Newline rest)))
		    (to-cffi 
		     `(,what ,@(if (stringp (car rest)) 
				 rest 
				 (cons (or name (cadr type)) rest)))))))
	       ((stringp (car type))
		`(defctype ,(string-conv name)
		     ,(cffi-type type))))))
      (:struct
       (when args
	 (destructuring-bind (to-name &rest els) args
	   (when to-name
	     `(defcstruct ,(string-conv to-name)
		,@(cffi-struct-code els))))))
      (:enum
       (destructuring-bind (to-name &rest els) args
	 `(defcenum ,to-name
	    ,@(mapcar (lambda (a) 
			(if (listp a)
			  `(,(string-conv (car a))
			     ,(read-from-string (cadr a)))))
		      els))))
      (:define ;TODO, translate constants?
       ))))
