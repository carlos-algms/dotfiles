;; extends

(jsx_opening_element
  name: (member_expression) @tag.opening (#set! "priority" 160)
  )

(jsx_opening_element
  name: (member_expression
          object: (identifier) @tag.opening (#set! "priority" 160)
          )
  )

(jsx_closing_element
  name: (member_expression) @tag.closing (#set! "priority" 160)
  )

(jsx_self_closing_element
  name: (member_expression
          object: (identifier)  @tag.selfClosing (#set! "priority" 160)
          )
  )

