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

(lexical_declaration
  (variable_declarator
    value: (new_expression
             constructor: (identifier) @new.identifier (#set! "priority" 150)
             )
    )
  )

(namespace_import
  (identifier) @import.identifier
  )
