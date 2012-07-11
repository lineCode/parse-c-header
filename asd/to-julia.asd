
(defsystem :to-julia
  :depends-on (:external-program :parse-c-header :j-string-utils :alexandria)
  :description "Makes julia source files that FFI C functions, based on a header.
The code uses get-c.j(also in src/ here)"
  :serial t
  :author "Jasper den Ouden"
  :components ((:module "../src"
                 :components ((:file "to-julia")))))
