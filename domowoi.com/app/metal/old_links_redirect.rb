# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class OldLinksRedirect
  def self.call(env)
    path = env["PATH_INFO"]
    if path =~ %r{^(.*)/at/([^?]+)}
      root, location = $1, $2.split('/')
      location -= ['Мир']
      adress = Adress::World.new
      new_location = []
      location.each do |an| 
        adress = adress.children.find_by_name(an)
        new_location << adress.urlfy_name
      end
      path = "#{root}/v/#{new_location.join('/')}"
    end
    
    case path
    when %r{^/users/groups/([^/?]+)([^?]*)}
      case $1
      when 'agent'
        path = "/agenty#$2"
      when 'maklers'
        path = "/maklery#$2"
      when 'individual'
        path = "/sobstvenniki#$2"
      end
    when %r{^/users}
      path = path.sub(%r{^/users}, '/polzovateli')
    when %r{^/agencies}
      path = path.sub('/agencies', '/agentstva')
    when %r{^/search}
      path = path.sub('/search', '/poisk')
    when %r{^/post}
      path = path.sub('/post', '/razmestit')
    when %r{^/objekts/(\d+)/?$}
      path = "/obyavleniya/#$1"
    end
    
    if path =~ %r{^/(poisk|razmestit)/(Sale|Rent|RentDay)/([^/]+)(/?.*?)$}
      path = '/'+[$1, NDV_DEAL_URL_MAP[$2], NDV_TYPE_URL_MAP[$3]].join('/') + $4
    end

    if path =~ Regexp.new("\\b(#{NDV_TYPE_URL_MAP.keys.join('|')})\\b")
      path = path.sub($1, NDV_TYPE_URL_MAP[$1])
    end
    
    if path != env['PATH_INFO']
      [301, {"Location" => path}, ["Page moved to #{path}\n"]]
    else
      [404, {"Content-Type" => "text/html"}, ["Not Found"]]
    end
  end
end
