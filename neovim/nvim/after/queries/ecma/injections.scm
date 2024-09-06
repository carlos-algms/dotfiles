;; extends


;; GraphQL string
; A string that contains a GraphQL query, mutation, or fragment
 (variable_declarator
   name: (identifier)
   value: (template_string
            (string_fragment) @injection.content
            (#match? @injection.content "query|mutation|fragment")
            (#set! injection.include-children)
            (#set! injection.language "graphql")
            )
   )

; Apollo.gql`...`
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

; prisma $queryRaw
;;;; Disabled as it stopped working
; (call_expression
;   function: (await_expression
;               (member_expression
;                 object: (identifier)
;                 property: (property_identifier) @function.identifier (#eq? @function.identifier "$queryRaw")
;                 )
;               )
;   arguments: (template_string) @injection.content
;   (#offset! @injection.content 0 1 0 -1)
;   (#set! injection.include-children)
;   (#set! injection.language "sql")
;   )



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

