require 'formtastic/inputs/base'
require 'formtastic/inputs/basic'

module CustomInputs
  module Photo
    include Formtastic::Inputs::Base
    include Formtastic::Inputs::Basic

    def photo_input(method, options = {})
      basic_input_helper(:photo_inputs, :photo, method, options)
    end

  protected
    def photo_inputs(method, options)
      version = (options[:version] ? options[:version] : :thumb)
      inputs_html =
        template.image_tag(@object.photo_url(version).to_s, :id => (options[:id] + '_image'))
      inputs_html << file_field(method, :class => "shrinked")
      inputs_html << template.content_tag(:span, nil,
                                          :class => "message")
      inputs_html
    end
  end
end

