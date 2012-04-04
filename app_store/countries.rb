module AppStore
  class Countries
    include HTTParty
    base_uri "http://itunes.apple.com"
    headers  'X-Apple-Tz' => "0",
      'Accept-Language' => 'en-us, en;q=0.50',
      'Accept-Charset' => 'UTF-8',
      'X-Apple-Store-Front' => '143444,12',
      'User-Agent' => 'iTunes/10.1.2 (Windows; Microsoft Windows XP Professional Service Pack 3 (Build 2600)) AppleWebKit/533.19.4'

    class << self

      def fetch_all
        @@countries ||=
          begin
            raw_response = self.get('/WebObjects/MZStore.woa/wa/countrySelectorPage')
            @@countries = Nokogiri.parse(raw_response.body).search(".country").map{|v|
              flag = v.at(".country-flag > a > img").attr('src') rescue '' 
              {
                :code => v.attr('storefront'),
                :name => v.at(".country-name").text,
                :flag => flag,
                :abbr => (flag.split('/').last.split('.').first  rescue '')
              }
            }
          end
        @@countries
      end

    end
  end
end
