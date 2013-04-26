class Track < ActiveRecord::Base
  EXTNAME_FOR_RENAME = ".mp3"

  attr_accessible :attachment

  has_attached_file :attachment, :styles => { :original => { }}, :processors => [:convert_to_mp3]

  validates_attachment :attachment, :presence => true,
                                    :content_type => { :content_type => /mp3|mp4|audio\/mpeg/, },
                                    :size => { :in => 0..5.megabytes,:message => " must be less 5 MB" }

  after_save :get_duration


  private

  # Get track duration
  #
  def get_duration
    file_path = rename_mp4_to_mp3
    update_column(:duration, Cocaine::CommandLine.new(::SOX_CONFIG[:soxi_command], "-D :file", :file => file_path).run.to_f.round(2))
  end


  # Rename mp4 -> mp3, for correct work of sox
  #
  def rename_mp4_to_mp3

    file_path = attachment.path

    if (current_format = File.extname(self.attachment.path)) =~ /mp4/
      new_attachment_file_name = File.basename(self.attachment_file_name, File.extname(self.attachment_file_name)) + EXTNAME_FOR_RENAME
      file_path =  File.join(File.dirname(self.attachment.path), File.basename(self.attachment.path, current_format)+EXTNAME_FOR_RENAME)

      FileUtils.mv(self.attachment.path, file_path)
      update_column(:attachment_file_name, new_attachment_file_name)
    end

    file_path
  end

end
