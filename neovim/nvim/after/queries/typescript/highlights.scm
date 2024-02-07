;; extends

;; fix true, false, null, and undefined when used as types
(
 (literal_type) @type.literal (#set! "priority" 140)
)

(
 (literal_type
   (string) @type.literal.string (#set! "priority" 150)
   )
)
