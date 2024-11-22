;; extends

; fix true, false, null, and undefined when used as types
(
 (literal_type) @type.literal (#set! "priority" 140)
 )

(
 (literal_type
   (string) @type.literal.string (#set! "priority" 150)
   )
)

; Fix types when there's no LSP
(type_identifier) @type.identifier

; Fix for `typeof XXXXX`
(type_query
  (identifier) @type.identifier (#set! "priority" 150)
  )

; fix for `typeof XXX.zzz`
(type_query
  (member_expression) @type.identifier (#set! "priority" 160)
  )


(
 (nested_type_identifier
   module: (identifier) @type.module (#set! "priority" 150)
   name: (type_identifier) @type.member (#set! "priority" 150)
   )
 )

(class_declaration
  name: (type_identifier) @class.identifier (#set! "priority" 150)
  )

; Added to fix .d.ts functions
(function_signature
  (identifier) @function.declaration
  )


(type_annotation
  (type_identifier) @type.identifier (#set! "priority" 150)
  )


;; this is different from JavaScript
;; public_field_definition, there it is just a field_definition
(public_field_definition
  name: [
         (property_identifier)
         (private_property_identifier)
         ] @function.method
  value: [
          (function_expression)
          (arrow_function)
          ]
  )


(generic_type
  name: (type_identifier) @type.identifier (#set! "priority" 150)
  )

(predefined_type) @type.predefined


; Fix enums creation not being flagged as property
(enum_assignment
  name: (property_identifier) @variable.member (#set! "priority" 150)
  )


; Fix for styled with a type: `styled.div<Type>`
(variable_declarator
  name: (identifier) @function.styled (#set! "priority" 150)
  value: (binary_expression
           left: (binary_expression
                   left: (member_expression
                           object: (identifier) @_name (#match? @_name "styled")
                           )
                   right: (identifier) @type.identifier
                   )
           )
  )


;; Fix for `const Component = styled.button.attrs....` - Component set as function
(variable_declarator
  name: (identifier) @function.attrs.styled (#set! "priority" 150)
  value: (binary_expression
           left: (binary_expression
                   left: (call_expression
                           function: (member_expression
                                       object: (member_expression
                                                 object: (identifier) @_name (#match? @_name "styled")
                                                 )
                                       )
                           )
                   )
           )
  )
