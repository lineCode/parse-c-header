
(defsystem :parse-c-header
  :depends-on (:j-string-utils :alexandria)
  :description "Parses _preprocessed_ C _headers_."
  :serial t
  :author "Jasper den Ouden"
  :components ((:module "../src"
                 :components ((:file "parse-c-header")))))
