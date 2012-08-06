;;
;;  Copyright (C) 05-08-2012 Jasper den Ouden.
;;
;;  This is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published
;;  by the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;

(defpackage :parse-c-header
  (:use :common-lisp :alexandria :j-string-utils)
  (:export parse-c-body c-like-tokenize)
  (:documentation "Parses _preprocessed_ C _headers_."))

(in-package :parse-c-header)

;Tokenize(in j-string-utils) is ~37 lines, and
; sublisting-tokens(in j-seq-utils) ~23

;TODO make tokenize work with functions anyway.
; make `stop` ignore if inside {} (?)

(defun c-like-tokenize (input &key (one-expr t))
  "Tokenize in 'c-like' style, also makes it an m-expr."
  (tokenize input :stop (if one-expr ";" "") 
	    :ignore-start "#" :ignore-end (format nil "~%")
	    :white (format nil " ~T~%")
	    :singlets (format nil "=+*-/%&^$#!@?><\'\:,;")
	    :open "({[" :close ")}]" :keep-ignore-p :comment))
  
(defun type-var-handler (input)
  "Handles types as collected."
  (destructuring-bind (&optional var &rest type) input
    (cons var (reverse type))))

;;Now it is a matter of interpreting that..
(defun parse-c-body (mexpr &key attr-next type-next)
  "Parse toplevel body or arguments."
  (destructuring-bind (&optional car &rest cdr) mexpr
    (typecase car
      (string
       (string-case car
	 ("__attribute__" ;Not really looking into these yet.
	  ;(assert (null type-next))
	  (parse-c-body (cdr cdr) :attr-next (car cdr)
			:type-next type-next))
	 ("__typeof__" ;TODO
	  )
	 ("typedef" 
	  (assert (null type-next))
	  (parse-c-typedef cdr :attr-next attr-next))
	 ("struct"
	  (parse-c-struct cdr :type-next type-next))
	 ("union"
	  (parse-c-union cdr :type-next type-next))
	 ("enum"
	  (parse-c-enum cdr :type-next type-next))
	 ("void"
	  (parse-c-body cdr :attr-next attr-next :type-next 
			 (cons :void type-next)))
	 (("const" "static" "volatile"
	   "char" "short" "int" "long" "unsigned" "signed" 
	   "float" "double")
	  (parse-c-body cdr :attr-next attr-next :type-next 
			 (cons (intern (string-upcase car) :keyword)
			       type-next)))
	 ("return";Dont really expect to do anything else than headers i guess
	  (assert (null type-next)) (assert (null attr-next))
	  `((:return ,@(parse-c-body cdr))))
	 (t
	  (cond ((null cdr) 
		   `((:var ,@(type-var-handler (cons car type-next)))))
		((listp (car cdr)) ;Probably function.
		 (case (caar cdr)
		   (#\( (let ((i (or (position-if-not 
				      (curry #'eql #\Newline) (cdr cdr))
				     0)))
			  `((:function ,car
			       (:type ,(type-var-handler type-next)
				:attr ,attr-next)
			      ,(parse-c-args (car cdr))
			      ,@(parse-c-body (list(nth (+ i 1) cdr))))
			    ,@(parse-c-body (nthcdr (+ i 2) cdr)))))
		   (#\* );TODO what does it mean? 'Make it as a pointer??'
		   (#\[ (if (cdr cdr)
			  (parse-c-body (cdr cdr) :attr-next attr-next
			    :type-next `((:arr ,@(cdar cdr) ,@type-next)
					 ,car))
			  (list (type-var-handler
				 `(:var (:arr ,@(cdar cdr))
					,@type-next ,car)))))))
		(t ;Just some word, add as type.
		 (parse-c-body cdr :attr-next attr-next :type-next 
				(cons car type-next)))))))
      (null ;Otherwise we'd infinite-loop.
       nil)
      (list
       (case (car car)
	 (#\# (cons car (parse-c-body cdr))) ;TODO
	 (#\{ (append (parse-c-body (cdr car)) (parse-c-body cdr)))
	 (t   ;(error "Loose list, probably indicates a function as\
; argument, not yet supported."))
	      ;Can also be an comment.
	      (parse-c-body cdr))))
      ((or (eql  #\}) (eql #\)) (eql #\]))
       (error "`c-like-tokenize` should have filtered these out."))
      ((eql #\*)
       (parse-c-body cdr :attr-next attr-next 
		      :type-next `(,(car type-next) :ptr ,@(cdr type-next))))
      ((or (eql #\,) (eql #\;)) ;End a type.
       `((:var ,@(type-var-handler type-next)) ,@(parse-c-body cdr)))
      ((eql #\Newline)
       (parse-c-body cdr :attr-next attr-next :type-next type-next))
      ((or (eql #\Space) (eql #\Tab))
       (error "These shouldn't have come past parsing."))
      (character
       (error "Loose character of unidentified meaning: ~s" car))
      ((eql :comment)
       mexpr)
      (t
       (when car (error "What is ~s" car))))))
      
(defun parse-c-typedef (list &key attr-next)
  "Parses a typedef, deconstructing the `:var`"
  (let ((body (parse-c-body list :attr-next attr-next)))
    (case (caar body)
      (:var 
       `((:typedef ,@(cdar body))))
      ((:struct :enum)
       `((:typedef ,(cadr body) ,(car body))))
      (:function ;Not yet.
       `((:fun ,@body)))
      (t
       `((:wut ,@body))))))

(defun parse-c-struct (list &key type-next name)
  (typecase (car list)
    ((eql #\Newline)
     (parse-c-struct (cdr list) :type-next type-next :name (car list)))
    (null
     nil)
    (list 
     (destructuring-bind (({ &rest struct-code) &rest rest) list
       (assert (eql { #\{))
       `((:struct ,name ,@(parse-c-body struct-code)) ,@rest)))
    (string
     (parse-c-struct (cdr list) :type-next type-next :name (car list)))))
	  
(defun parse-c-union (&rest stuff)
  (declare (ignore stuff))
  '((:union))) ;TODO

(defun parse-c-enum (cdr &key type-next)
  (declare (ignore type-next))
  (multiple-value-bind (enum-list rest)
      (if (listp (car cdr))
	(values (car cdr)  (cdr cdr))
	(values (cadr cdr) (cddr cdr)))
    (assert (and (listp enum-list) (eql (car enum-list) #\{) t)  nil "~s" cdr)
    (labels
	((partial-detokenize (list)
	   "Attach some bits back together.
 (A sign that this code is rather bad.."
	   (when list
	     (case (car list)
	       ((#\+ #\-) (partial-detokenize
			   (cons (concat (list(car list)) (cadr list))
				 (cddr list))))
	       (t         (cons (car list) 
				(partial-detokenize (cdr list)))))))
	 (enum (list)
	   "Parses it recursively."
	   (destructuring-bind (first &optional second third fourth
				      &rest rest) list
	     (case second
	       (#\, (assert third nil "Comma, but nothing after.")
		    (cons first (enum (cddr list))))
	       (#\= (assert (or (not fourth) (eql fourth #\,)) nil
			    "Enum contents must be comma-separated, have ~a."
			    fourth)
		    (assert (or (not fourth) rest) nil
			    "Comma, but nothing afterward.")
		    (cons (list first third) (when rest (enum rest))))
	       (t   (if second (error "~s" list) 
		       (list first)))))))
      `((:enum ,(unless (listp (car cdr)) (car cdr))
	       ,@(enum(partial-detokenize (cdr enum-list)))) ,@rest))))

(defun parse-c-args (list)
  (assert (eql (car list) #\() nil "Argument list not delimited by () but\
 starts with ~s" (car list))
  (parse-c-body (cdr list)))
