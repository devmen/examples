require "formtastic/todo"
require "formtastic/phone_number"
require "formtastic/photo"
require "formtastic/attachment"

class Formtastic::FormBuilder
  include CustomInputs::Todo
  include CustomInputs::PhoneNumber
  include CustomInputs::Photo
  include CustomInputs::Attachment
end

