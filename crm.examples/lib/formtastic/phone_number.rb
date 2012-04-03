require 'formtastic/inputs/base'

module CustomInputs
  module PhoneNumber
    include Formtastic::Inputs::Base

    def phone_number_input(method, options = {})
      type_method = options[ :type ] || :name
      template.content_tag( :li, phone_number_inputs( method, type_method, options ),
                            :class => "phone_number" )
    end

  protected
    def phone_number_inputs(method, type_method, options)
      collection = options.delete( :collection )
      type_html_options = options.delete( :type_options ) || {}
      html_options = options.delete( :input_html ) || {}

      type_input_name = "#{@object_name}[#{type_method}]"

      field_id = generate_html_id(method, "")
      html_options[:id] = field_id

      inputs_html =
        select( type_method, collection, strip_formtastic_options(options) )

      inputs_html << text_field( method, html_options )

      label_options = options_for_label(options).merge(:input_name => type_input_name)
      label_options[:for] ||= html_options[:id]
      label(method, label_options) << inputs_html
    end
  end
end
