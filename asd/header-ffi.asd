
(defsystem :header-ffi
  :depends-on (:external-program :parse-c-header :j-string-utils :alexandria)
  :description "Functions helping you get the header files, a function
 from `:to-cffi`/`:to-julia` can be provided to convert it to there."
  :serial t
  :author "Jasper den Ouden"
  :components ((:module "../src"
                 :components ((:file "header-ffi")))))
