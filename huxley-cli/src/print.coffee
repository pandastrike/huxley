#===============================================================================
# Huxley - CLI Flag Parsing
#===============================================================================
# Huxley offers the ability to print its output in a couple different formats
# to accomodate scripting.

module.exports =

  print: (response, options) ->
    return unless response
    if options.json
      console.log JSON.stringify response, null, 2
    else if options.yaml
      # TODO: Support YAML output.
      throw "YAML output isn't supported yet."
    else
      console.log "\n"
      console.log response.toString()
