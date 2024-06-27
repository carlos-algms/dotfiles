;; extends
[
  (php_tag)
  "?>"
  ] @tag

[
  "->"
  ] @punctuation.delimiter

(
 (comment) @comment.documentation
 (#lua-match? @comment.documentation "^/[*][*][^*].*[*]/$")
 )

(class_declaration
  name: (name) @class
  )

(property_element
  (variable_name) @property.declaration
  (#set! "priority" 110)
  )


; Normalize $ as part of the constant name
((variable_name) @constant
  (#lua-match? @constant "^\[$]_?[A-Z][A-Z%d_]*$"))

((variable_name) @constant.builtin
  (#lua-match? @constant.builtin "^\[$]__[A-Z][A-Z%d_]+__$"))
