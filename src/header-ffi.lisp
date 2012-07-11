;;
;;  Copyright (C) 11-07-2012 Jasper den Ouden.
;;
;;  This is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published
;;  by the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;

(defpackage :header-ffi
  (:use :common-lisp :alexandria :j-string-utils
	:parse-c-header :external-program)
  (:export preprocessed-stream-ffi header-ffi
	   defines-stream-ffi)
  (:documentation "Functions helping you get the header files, a function
 from `:to-cffi`/`:to-julia` can be provided to convert it to there."))

(in-package :header-ffi)

(defun eof-p (stream)
  "TODO This function is terrible."
  (let ((ch (read-char stream nil :eof)))
    (typecase ch
      (character  (unread-char ch stream) nil)
      ((eql :eof) t)
      (t          (error "Wth did `read-char` return? ~a" ch)))))

(defun preprocessed-stream-ffi (stream ffi-fun)
  "Reads pre-processed C-header in the stream."
  (do ((list nil))
      ((eof-p stream) `(progn ,@(reverse list)))
    (when-let (got (c-like-tokenize stream))
      (when-let (add (funcall ffi-fun (car(parse-c-body got))))
	(push add list)))))

(defun defines-stream-ffi (stream ffi-fun)
  "Stream of defines added separately."
  (remove-if #'null
    (line-by-line stream
      (lambda (line)
	(when (start-str= line "#define ")
	  (funcall ffi-fun
		   (cons :define (tokenize (subseq line 8)))))))))

(defun find-header-file (file sequence)
  "Finds a file given a sequence of paths to look in."
  (dolist (path sequence (values file t))
    (when (probe-file (concat path file))
      (return-from find-header-file (concat path file)))))

(defun header-ffi
    (header-file ffi-fun &key (sequence '("." "/usr/include/"))
     (header-file-raw (find-header-file header-file sequence))
     (program "gcc") (args (list "-E" header-file-raw))
     defines-p)
  "Reads preprocessed header file, returning ffi code..
The ffi-function could be `to-cffi:cffi-code` or `to-julia:julia-code` for 
 instance.(but `#'print`, or `#'identity` etc, also work, listing it."
  (append
   (with-input-from-string 
       (preprocessed ;Me want stream innie outtie same order. Complicated?
	(with-output-to-string (out)
	  (run program args :output out)))
     (preprocessed-stream-ffi preprocessed ffi-fun))
   (when defines-p ;Maor stream suckage.
     (with-input-from-string
	 (stream (with-output-to-string (grep-stream)
		   (run "grep" (list "#define " header-file-raw)
			:output grep-stream)))
       (defines-stream-ffi stream ffi-fun)))))
