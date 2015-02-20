{underscored} = require "fairmont"
for status, message of (require "http").STATUS_CODES
  do (status, message) ->
    if status >= 400
      module.exports[(underscored message)] = ->
        error = new Error message
        error.status = status
        error
