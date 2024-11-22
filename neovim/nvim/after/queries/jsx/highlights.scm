;; extends

; Fix for JSX tags, otherwise they look like normal variable and property
(jsx_opening_element
  name: (member_expression) @tag.jsx.opening (#set! "priority" 160)
  )
;

(jsx_closing_element
  name: (member_expression) @tag.jsx.closing (#set! "priority" 160)
  )

; fix for self closing tags as a Property
; <Parent.Root .... />
(jsx_self_closing_element
  name: (member_expression
          object: (identifier)  @tag.selfClosing (#set! "priority" 160)
          property: (property_identifier) @tag.selfClosing (#set! "priority" 160)
          )
  )

