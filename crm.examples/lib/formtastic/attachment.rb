require 'formtastic/inputs/base'
require 'formtastic/inputs/basic'

module CustomInputs
  module Attachment
    include Formtastic::Inputs::Base
    include Formtastic::Inputs::Basic

    def attachment_input(method, options = {})
      attachment_inputs(method, options)
    end

  protected
    def attachment_inputs(method, options)
      inputs_html = template.image_tag(options[:image], options[:image_opt])
      inputs_html << file_field(method, :class => "shrinked")
      inputs_html << template.content_tag(:span, extract_fname, :class => "message")
      inputs_html
    end

    def extract_fname
      unless @object.attachment.file.nil?
        File.basename File.join(Rails.root, 'public', @object.attachment.to_s)
      end
    end
  end
end

