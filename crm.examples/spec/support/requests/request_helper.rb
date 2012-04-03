module NavigationHelper
  def go(*args)
    path = nil
    case args.first
    when String
      path = args.first
    when ActiveRecord::Base
      resource = args.shift
      action = args.first
      path = '/'
      path << resource.class.name.underscore.pluralize
      path << '/'
      path << resource.id.to_s
      if action.is_a?(Symbol)
        path << '/'
        path << action.to_s
      end
    when Class
      resource_class = args.shift
      if resource_class.superclass == ActiveRecord::Base
        action = args.first
        path = '/'
        path << resource_class.name.underscore.pluralize
        if action
          path << '/'
          path << action.to_s
        end
      end
    end

    if path
      visit "http://devmen.lvh.me#{path}"
    end
  end
end
