;; extends


; Fix styled when used along with TypeScript types
; styled.div<Type>`css`
(call_expression
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


; styled(Component).attr({ ... })<Type>`css`
(call_expression
  function: (non_null_expression
              (instantiation_expression
                (call_expression
                  function: (member_expression
                              object: (call_expression
                                        function: (identifier) @_name
                                        (#eq? @_name "styled")
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
