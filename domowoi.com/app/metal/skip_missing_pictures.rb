# Allow the metal piece to run in isolation
#require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
if Rails.env.to_s == 'development' || Rails.root.to_s =~ /devel/
  require 'digest/md5'
  class SkipMissingPictures
    @nlos = {}
    def self.get_image(n)
      @nlos[n % 6] ||= begin
        image_name = Rails.root + "public/images/other/nlo/#{n % 6}.gif"
        image = File.read(image_name)
        [image, Digest::MD5.hexdigest(image_name)]
      end
    end
    def self.call(env)
      if env["PATH_INFO"] =~ %r{^/system/(users|images|agencies)/(\d+)/(\d+)/(\d+)}
        n = "#$2#$3#$4".to_i
        image, md5 = get_image(n)
        if env["HTTP_IF_NONE_MATCH"] == md5
          [304, {"Cache-Control" => 'public, max-age=3600'}, []]
        else
          [200, {"Content-Type" => "image/gif", "ETag" => md5, "Cache-Control" => 'public, max-age=3600'}, [ image ]]
        end
      else
        [404, {"Content-Type" => "text/html"}, ["Not Found"]]
      end
    end
  end
else
  class SkipMissingPictures
    def self.call(env)
      [404, nil, nil]
    end
  end
end
