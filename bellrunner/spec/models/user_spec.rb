require 'spec_helper'

describe User do
  let(:user){ create(:user) }
  describe ".association" do
    it {should have_many(:tracks)}
  end

  describe ".guest_user" do
    specify "should create user" do
      expect{ User.guest_user }.to change{ User.count}.by(1)
    end
  end

  describe "#duration" do
    specify "should return duration all tracks" do
      user.tracks << create(:track_with_mp3)
      user.tracks << create(:track_with_mp3)
      user.duration.should eq(10.2)
    end
  end

  describe "#limit_of_duration?" do
    subject{ user }

    context "if duration tracks great 30 minutes" do
      before{  user.stub(:duration).and_return(31.minutes) }
      its(:limit_of_duration?) { should be_true }
    end

    context "if duration tracks less 30 minutes" do
      before{ user.stub(:duration).and_return(1.minutes) }
      its(:limit_of_duration?) { should be_false }
    end

  end

end
