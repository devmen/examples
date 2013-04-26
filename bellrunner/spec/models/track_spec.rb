require 'spec_helper'

describe Track do

  it { should have_attached_file(:attachment) }

  describe ".validations" do
    it { should validate_attachment_presence(:attachment) }
    it { should validate_attachment_content_type(:attachment).
      allowing('audio/mp3', 'video/mp4', 'audio/mpeg').rejecting('text/plain', 'text/xml', 'image/gif' , 'image/jpg')
    }
    it { should validate_attachment_size(:attachment).less_than(5.megabytes) }
  end

  it { should allow_mass_assignment_of(:attachment) }

  describe "#callback" do
    specify "after create should save duration track (mp3)" do
      @track = create(:track_with_mp3)
      @track.duration.should eq(5.1)
    end

    specify "after create should save duration track (mp4)" do
      @track = create(:track_with_mp4)
      @track.duration.should eq(5.02)
    end

  end

end
