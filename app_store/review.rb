module AppStore
  class Review
    attr_reader :text, :title, :reviewer, :date

    def initialize(options = {})
      @text = options[:text]
      @title = options[:title]
      @reviewer = options[:reviewer]
      @date = options[:date]
    end

    def to_s
      "\n#{@title} by #{@reviewer} - #{@date.to_s}\n=> #{@text}"
    end

    def to_hash
      { :text => @text, :title => @title, :reviewer => @reviewer, :date => @date }
    end

    def ==(obj)
      self.text == obj.text && self.title == obj.title && self.reviewer == obj.reviewer && self.date == obj.date
    end

    def looking_for_codes(codes)
      found_codes = []
      codes.to_a.each do |code|
        found_codes.push(code) if @title.include?(code) || @text.include?(code)
      end

      found_codes
    end
  end
end
