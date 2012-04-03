require 'formtastic/inputs/base'
require 'formtastic/inputs/string_input'

module CustomInputs
  module Todo
    include Formtastic::Inputs::Base
    include Formtastic::Inputs::StringInput

    def todo_input( method, options = {} )
      flag_method = options[:flag] || :done
      todo_inputs( method, flag_method, options )
    end

  protected

    def todo_inputs( method, flag_method, options )
      maxlength = options[ :maxlength ] || 255
      checked = @object.send(flag_method.to_sym)
      string_options = { :class => ( checked ? "done" : "" ), :rows => 1, :maxlength => maxlength }
      string_options[ :readonly ] = "readonly" if checked

      todo_boolean_input( flag_method, options ) <<
        text_area( method, string_options )
    end

    def todo_boolean_input( method, options )
      html_options  = options.delete(:input_html) || {}
      checked_value = options.delete(:checked_value) || '1'
      unchecked_value = options.delete(:unchecked_value) || '0'
      checked = @object && ActionView::Helpers::InstanceTag.check_box_checked?(@object.send(:"#{method}"), checked_value)

      html_options[:id] = html_options[:id] || generate_html_id(method, "")
      input = template.check_box_tag(
        "#{@object_name}[#{method}]",
        checked_value,
        checked,
        html_options
      )

      template.hidden_field_tag((html_options[:name] || "#{@object_name}[#{method}]"), unchecked_value, :id => nil) << input
    end
  end
end
