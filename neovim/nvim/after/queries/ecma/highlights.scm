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

(pair
  key: (property_identifier) @variable.member (#set! "priority" 150)
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
