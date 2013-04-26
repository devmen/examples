module Paperclip
  class ConvertToMp3 < Processor

    def initialize(file, options = { }, attachment = nil)
      super
      @file = file
      @instance = options[:instance]
      @attachment = attachment
      @options = options
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
    end

    def make
      return @file unless @attachment.content_type.to_s  =~ /mp4/

      src = @file
      dst = Tempfile.new([@basename.to_s, ".mp3"])
      dst.binmode

      begin
        success = Paperclip.run("sox", ":file_from :file_to", :file_from => src.path, :file_to => dst.path)

      rescue Cocaine::CommandLineError => ex
        Paperclip.log("Convert mp4 to mp3: #{ex.message}")
        raise Paperclip::Errors::CommandNotFoundError, "Convert mp4 to mp3: #{ex.message}"
      end

      dst
    end

  end
end
