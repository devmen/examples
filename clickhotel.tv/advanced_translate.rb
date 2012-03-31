# encoding: utf-8
module Platform
  module Models
    module AdvancedTranslate
      extend ActiveSupport::Concern
      module ClassMethods
        def advanced_translate *args
          I18n.available_locales.map{|v| v.to_s.downcase.gsub('-', '_').to_sym}.each do |locale|
            args.each do |m|
              attr_accessor   :"#{m}_#{locale}"
              define_method("#{m}_#{locale}=") { |value|  write_attribute(m, value, {:locale => locale} )  }
              define_method("#{m}_#{locale}") { read_attribute(m, {:locale => locale})  }
            end
          end
        end
      end
    end
  end
end
