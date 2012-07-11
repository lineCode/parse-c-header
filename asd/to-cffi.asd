
(defsystem :to-cffi
  :depends-on (:cffi :j-string-utils)
  :description "Take input as from parse-c-header and turn it into cffi
 code."
  :serial t
  :author "Jasper den Ouden"
  :components ((:module "../src"
                 :components ((:file "to-cffi")))))
