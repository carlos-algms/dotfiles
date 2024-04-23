;; extends

;; fix true, false, null, and undefined when used as types
(
 (literal_type) @type.literal (#set! "priority" 140)
 )

(
 (literal_type
   (string) @type.literal.string (#set! "priority" 150)
   )
)

(variable_declarator
  name: (identifier) @function (#set! "priority" 150)
  value: [(function_expression) (arrow_function)]
  )

(class_declaration
  name: (type_identifier) @class.identifier
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

(import_statement
  (import_clause
    (named_imports
      (import_specifier
        name: (identifier) @import.identifier
        )
      )
    )
  )

(import_statement
  (import_clause
    (named_imports
      (import_specifier
        alias: (identifier) @import.alias
        )
      )
    )
  )

(import_clause
  (identifier) @import.identifier
  )

(namespace_import
  (identifier) @import.identifier
  )

(lexical_declaration
  (variable_declarator
    value: (new_expression
             constructor: (identifier) @new.identifier (#set! "priority" 150)
             )
    )
  )


; (
;  (identifier) @variable
;  (#match? @variable "^[A-Z]")
;  (#set! "priority" 120)
;  )
