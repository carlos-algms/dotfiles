;; extends

(new_expression
  constructor: (identifier) @constructor (#set! "priority" 150)
  )

((this) @variable.builtin.this
 ; (#eq? @variable.builtin.this "this")
 )

(public_field_definition
  name: (property_identifier) @function.method
  value: (arrow_function)
  )
