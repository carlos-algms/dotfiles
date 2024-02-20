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

(variable_declarator
  name: (identifier) @variable.declaration (#set! "priority" 120)
  )

; (
;  (identifier) @variable
;  (#match? @variable "^[A-Z]")
;  (#set! "priority" 120)
;  )
