;; extends

(new_expression
  constructor: (identifier) @constructor (#set! "priority" 150)
  )

((this) @variable.builtin.this
 ; (#eq? @variable.builtin.this "this")
 )


(member_expression
   (identifier) @variable.identifier (#set! "priority" 150)
    )
