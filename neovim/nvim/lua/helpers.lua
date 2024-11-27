
--- @alias AutoCmdEvent
--- | "BufAdd"
--- | "BufDelete"
--- | "BufEnter"
--- | "BufFilePost"
--- | "BufFilePre"
--- | "BufHidden"
--- | "BufLeave"
--- | "BufModifiedSet"
--- | "BufNew"
--- | "BufNewFile"
--- | "BufRead"
--- | "BufReadCmd"
--- | "BufReadPost"
--- | "BufReadPre"
--- | "BufUnload"
--- | "BufWinEnter"
--- | "BufWinLeave"
--- | "BufWipeout"
--- | "BufWrite"
--- | "BufWriteCmd"
--- | "BufWritePost"
--- | "BufWritePre"

--- @class AutoCmdCallbackEvent
--- @field public id number
--- @field public event string
--- @field public group number
--- @field public match string
--- @field public buf number
--- @field public file string
--- @field public data any
