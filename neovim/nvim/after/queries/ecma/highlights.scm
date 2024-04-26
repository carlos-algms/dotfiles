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
    )

; I had to increase the priority, as LSP was overriding and setting to @identifier
(call_expression
  function: (identifier) @function.call (#set! "priority" 150)
  )

