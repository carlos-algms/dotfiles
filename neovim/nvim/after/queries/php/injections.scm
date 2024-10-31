;; extends

; highlight sql in Laravel
; DB::statement("... SQL HERE ...") it must be double quoted
(scoped_call_expression
  scope: (name)
  name: (name) @function.identifier (#eq? @function.identifier "statement")
  arguments: (arguments
               (argument
                 (encapsed_string) @injection.content
                 (#offset! @injection.content 0 1 0 -1)
                 (#set! injection.include-children)
                 (#set! injection.language "sql")
                 )
               )

  )

