require 'spec_helper'

describe MixTrack do
  describe ".mixing_tracks" do

    specify "should create mix track", :constraint => 'slow' do
      @track1 = create(:track_with_mp3_31Mb)
      @mix_track = MixTrack.mixing_tracks([@track1])
      @mix_track.is_a?(MixTrack).should be_true
      @mix_track.attachment.path.should be_same_file_as(File.join(Rails.root, 'spec', 'fixtures', 'audio', 'mix-track.mp3'))
    end

  end
  describe ".sort_files" do
    let(:not_ordered_list){
      [ "./sound_1", "./sound_10", "./sound_11", "./sound_2", "./sound_3", "./sound_4",
       "./sound_5", "./sound_6", "./sound_7", "./sound_8", "./sound_9" ]  }

    let(:orderd_list){
      [ "./sound_1", "./sound_2", "./sound_3", "./sound_4", "./sound_5", "./sound_6",
       "./sound_7", "./sound_8", "./sound_9", "./sound_10", "./sound_11" ]  }

    specify "should orderd files by digit in filename" do
      MixTrack.sort_files(not_ordered_list).should eq(orderd_list)
    end

  end
end
