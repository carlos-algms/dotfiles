;; extends
[
  (php_tag)
  "?>"
  ] @tag


(class_declaration
  name: (name) @class
  )

(property_element
  (variable_name) @property.declaration
  (#set! "priority" 110)
  )


