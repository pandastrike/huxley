#===============================================================================
# Huxley - Resource "profile"
#===============================================================================
# Huxley does not have "users".  We prefer to think of people as humans, humans
# with a use-case that may vary from person to person.  Therefore, the resource
# used to track these details is called "profile"

# TODO
create_profile = async ({config}) ->
  {questions} = require (join __dirname, "./interviews/profile-create")
  answers = yield run_interview questions
  config.user_details = answers
  #yield api.create_user config

# TODO
rm_profile = async ({config}) ->
  {questions} = require (join __dirname, "./interviews/profile-rm")
  answers = yield run_interview questions
  #yield api.delete_user answers
