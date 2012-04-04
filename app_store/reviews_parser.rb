module AppStore
  class ReviewsParser
    def initialize(country_code, product_id)
      @product_id = product_id
      @country_code = country_code
      @request_headers = {
        'X-Apple-Tz' => "0",
        'Accept-Language' => 'en-us, en;q=0.50',
        'Accept-Charset' => 'UTF-8',
        'X-Apple-Store-Front' => @country_code,
        'User-Agent' => 'iTunes/10.1.2 (Windows; Microsoft Windows XP Professional Service Pack 3 (Build 2600)) AppleWebKit/533.19.4'
      }
    end

    def total_pages
      @reviews_document ||= fetch_reviews_page
      @reviews_document.css(".paginated-content").first[:"total-number-of-pages"].to_i rescue 0
    end

    def customer_reviews(page = nil)
      reviews_page = fetch_reviews_page(page)
      return [] if reviews_page.nil?

      reviews = []
      reviews_page.css(".customer-review").each do |div|
        reviews << AppStore::Review.new(:text => review_text(div), :title => review_title(div), :reviewer => reviewer(div), :date => review_date(div))
      end

      reviews
    end

    private
    def fetch_page(page_url)
      c = Curl::Easy.new(page_url) do |curl|
        curl.headers = @request_headers
      end
      c.perform

      Nokogiri::HTML(c.body_str)
    end

    def fetch_product_page
      @product_document = fetch_page(url)
    end

    def fetch_reviews_page(page = nil)
      if page.nil?
        @reviews_document = fetch_page(reviews_url) unless reviews_url.nil?
      else
        fetch_page "#{pages_url}&page=#{page}"
      end
    end

    def reviews_url
      @product_document ||= fetch_product_page
      @product_document.at_css("div[client-side-include-url]")[:"client-side-include-url"] rescue nil
    end

    def pages_url
      @reviews_document ||= fetch_reviews_page
      "http://itunes.apple.com#{@reviews_document.at_css(".current-reviews")[:"goto-page-href"]}&sort=4" unless @reviews_document.nil?
    end

    def url
      "http://itunes.apple.com/app/id#{@product_id}?mt=8"
    end

    def review_text(div)
      div.css(".content").text.strip
    end

    def review_title(div)
      div.at_css("span.customerReviewTitle").text
    end

    def reviewer(div)
      div.at_css("a.reviewer").text.strip
    end

    def review_date(div)
      div.at_css("span.user-info").text.split("-").drop(2).join("-").strip
    end
  end
end
