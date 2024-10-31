;; extends

; There are some links in the Docs as <htttps://url.com> and these were not tagged as URL
(
 (word) @string.special.url
 (#offset! @string.special.url 0 1 0 -1)
 (#match? @string.special.url "https?://")
 )

