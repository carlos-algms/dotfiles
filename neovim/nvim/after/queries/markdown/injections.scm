;; extends
; inject TSX into inline nodes starting with import/export
((inline) @injection.content
  (#lua-match? @injection.content "^%s*import")
  (#not-has-ancestor? @injection.content list_item)
  (#set! injection.include-children)
  (#set! injection.language "typescript")
  )

((inline) @injection.content
  (#lua-match? @injection.content "^%s*export")
  (#not-has-ancestor? @injection.content list_item)
  (#set! injection.include-children)
  (#set! injection.language "typescript")
  )
