;; extends
; inject TSX into inline nodes starting with import/export
((inline) @injection.content
          (#lua-match? @injection.content "^%s*import")
          (#set! injection.include-children)
          (#set! injection.language "typescript")
          )

((inline) @injection.content
          (#lua-match? @injection.content "^%s*export")
          (#set! injection.include-children)
          (#set! injection.language "typescript")
          )
