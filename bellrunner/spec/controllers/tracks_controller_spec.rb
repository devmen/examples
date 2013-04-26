require 'spec_helper'

describe TracksController do

  describe "#index" do
    before{ get "index" }
    it { should respond_with(:success) }
    it { should render_template(:index) }
    it { should assign_to(:track) }
  end

  describe "#create" do
    context "valid params" do
      before{
        expect{
          post :create, track: {
            attachment: fixture_file_upload("/audio/mr_jump.mp3", "audio/mp3")
          }
        }.to change{ Track.count}.by(1)

      }

      it { should set_the_flash.to("Track uploaded.") }
      it { should redirect_to(tracks_path) }
    end

    context "invalid params" do
      before{
        expect{ post :create, track: {    } }.to_not change{ Track.count}
      }

      it { should_not set_the_flash.to("Track uploaded.") }
      it { should render_template(:index) }
      it { should respond_with(:unprocessable_entity) }
    end

  end

  describe "#download" do
    context "invalid mixing" do
      before{
        MixTrack.stub(:mixing_tracks).and_return(nil)
        get :download
      }
      it { should set_the_flash.to("Mixing errors.") }
      it { should redirect_to(tracks_path) }

    end

  end
end
