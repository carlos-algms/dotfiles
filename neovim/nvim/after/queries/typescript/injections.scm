;; extends

(variable_declarator
  name: (identifier)
  value: (binary_expression
           left: (binary_expression
                   left: (member_expression
                           object: ((identifier) @_name
                                                 (#eq? @_name "styled")
                                                 )
                           property: (property_identifier)
                           )
                   right: (identifier)
                   )
           right: ((template_string) @injection.content
                                     (#offset! @injection.content 0 1 0 -1)
                                     (#set! injection.include-children)
                                     (#set! injection.language "styled")
                                     )
           )
  )


;; Fix for `styled.div<{ obj: xx}>`
(variable_declarator
  name: (identifier)
  value: (call_expression
           function: (non_null_expression
                       (instantiation_expression
                         (member_expression
                           object: ((identifier) @_name
                                                  (#eq? @_name "styled")
                                                  )
                           )
                         )
                       )
           arguments: ((template_string) @injection.content
                                     (#offset! @injection.content 0 1 0 -1)
                                     (#set! injection.include-children)
                                     (#set! injection.language "styled")
                                     )
           )
  )

;; Fix for `styled.div.attrs<xxx>`
(call_expression
  function: (non_null_expression
              (instantiation_expression
                (call_expression
                  function: (member_expression
                              object: (member_expression
                                        object: ((identifier) @_name
                                                              (#eq? @_name "styled")
                                                              )
                                        )
                              )
                  )
                )
              )
  arguments: ((template_string) @injection.content
                                (#offset! @injection.content 0 1 0 -1)
                                (#set! injection.include-children)
                                (#set! injection.language "styled")
                                )
  )


;; Fix for a complex `styled.div.attrs<Type>....`
(binary_expression
  left: (binary_expression
          left: (call_expression
                  function: (member_expression
                              object: (member_expression
                                        object: (identifier) @function.styled.attrs
                                        )
                              )
                  )
          right: (identifier))
  right: ((template_string) @injection.content
                            (#offset! @injection.content 0 1 0 -1)
                            (#set! injection.include-children)
                            (#set! injection.language "styled")
                            )
  )
