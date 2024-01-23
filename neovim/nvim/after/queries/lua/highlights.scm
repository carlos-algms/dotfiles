;; extends

;; increase the priority as the LSP was making it white
(table_constructor
  (field
    name: (
           (identifier) @function
           (#set! "priority" 140)
           )
    value: (function_definition)
    )
  )

 (function_call
   name: (identifier)
   @function.call.lua
   (#set! "priority" 140)
   )
