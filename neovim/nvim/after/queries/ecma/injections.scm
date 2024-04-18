;; extends


; GraphQL string
 (variable_declarator
   name: (identifier)
   value: (template_string
            (string_fragment) @injection.content
            (#match? @injection.content "query|mutation|fragment")
            (#set! injection.include-children)
            (#set! injection.language "graphql")
            )
   )


(call_expression
  function: (member_expression
              object: (identifier)
              property: (property_identifier) @function.identifier (#eq? @function.identifier "gql")
              )
  arguments: (template_string
               (string_fragment) @injection.content
               (#set! injection.include-children)
               (#set! injection.language "graphql")
               )
  )


; CSS / styled-components
; solved by running: TSInstall styled
; the queries included by default: https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/ecma/injections.scm
; (call_expression
;   function: (member_expression
;               object: (identifier) @identifier (#eq? @identifier "styled")
;               )
;   arguments: (template_string
;                (string_fragment) @injection.content
;                (#set! injection.include-children)
;                (#set! injection.language "styled")
;                )
;   )

; (call_expression
;   function: (identifier)
;   arguments: (template_string
;                (string_fragment) @scss
;                )
;   )


; (call_expression
;   function: (member_expression
;               object: (identifier) @identifier (#eq? @identifier "styled")
;               )
;   arguments: (template_string
;                (string_fragment) @scss
;                )
;   )

