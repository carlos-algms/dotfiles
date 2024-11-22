;; extends

(
 (string_fragment) @keyword.directive
 (#eq? @keyword.directive "use client")
 )

(new_expression
  constructor: (identifier) @constructor (#set! "priority" 150)
  )

((this) @variable.builtin.this
 ; (#eq? @variable.builtin.this "this")
 )


(member_expression
  (identifier) @variable.identifier (#set! "priority" 150)
  ; If reenable this, add a reason, it broke the jsx syntax <Parent.Tag />
  ; I'll need to re-enable it, it breaks simple property access like `this.foo`
  (property_identifier) @variable.member (#set! "priority" 150)
  )

; Fix a property in an object, sometimes it was flagged as a variable
; { foo: 'bar' }
(pair
  key: (property_identifier) @variable.member (#set! "priority" 150)
  )

; fic a function as an object property
; { foo: () => {} }
(pair
  key: (property_identifier) @function.method (#set! "priority" 150)
  value: (arrow_function)
  )

; I had to increase the priority, as LSP was overriding and setting to @identifier
(call_expression
  function: (identifier) @function.call (#set! "priority" 150)
  )

(call_expression
  function: (member_expression
              property: (property_identifier) @function.call (#set! "priority" 150)
              )
  )

(call_expression
  function: (super) @function.call (#set! "priority" 150)
  )


; fix for `const Component = styled.xxx`, `Component` wasn't a Function
(variable_declarator
  name: (identifier) @function.definition (#set! "priority" 150)
  value: (call_expression) @_name (#match? @_name "^styled")
  )


(variable_declarator
  name: (identifier) @function.declaration (#set! "priority" 150)
  value: [(function_expression) (arrow_function)]
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
        alias: (identifier) @import.alias (#set! "priority" 150)
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

; this fixes forwardRef() or lazy() calls without React in front of it
(variable_declarator
  name: (identifier) @function.react.definition (#set! "priority" 150)
  value: (call_expression
           function: (identifier) @_name (#match? @_name "forwardRef|createContext|lazy")
           )
  )

; this fixes React.**
(variable_declarator
  name: (identifier) @function.react (#set! "priority" 150)
  value: (call_expression
           function: (member_expression
                       object: (identifier)
                       property: (property_identifier) @_name (#match? @_name "forwardRef|createContext|lazy")
                       )
           )
  )

; Fix for styled.div : div wasn't a function
(member_expression
  object: (identifier) @_name (#match? @_name "styled")
  property: (property_identifier) @function.styled (#set! "priority" 150)
  )
