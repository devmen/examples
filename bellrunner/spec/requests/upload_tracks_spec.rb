require 'spec_helper'
describe "Upload Tracks" do

  describe "#index" do
    context "if user uploaded tracks of less than 30 mitutes" do

      before{
        User.any_instance.stub(:limit_of_duration?).and_return(false)
        visit "/tracks"
      }

      specify "should show upload form" do
        page.should have_selector(:xpath, "//form[@id='new_track']")
      end
      specify "should not show download link" do
        page.should_not have_selector(:xpath, "//a[@href='/tracks/download.json']")
      end
    end

    context "if user uploaded tracks of equal or great 30 minutes" do
      before{
        User.any_instance.stub(:limit_of_duration?).and_return(true)
        visit "/tracks"
      }

      specify "should not show upload form" do
        page.should_not have_selector(:xpath, "//form[@id='new_track']")
      end

      specify "should show download link" do
        page.should have_selector(:xpath, "//a[@href='/tracks/download.json']")
      end

    end

  end
  describe "#create" do

    context "invalid" do
      before{ visit "/tracks" }

      specify "Attachment can't be blank" do
        expect{  click_button "Save"}.to_not change{ Track.count }
        page.should have_content("Attachment can't be blank")
      end

      specify "Attachment content type is invalid" do
        attach_file "track[attachment]", File.join(Rails.root, "spec", "fixtures", "audio", "mr_jump.jpg")

        expect{  click_button "Save"}.to_not change{ Track.count }
        page.should have_content("Attachment content type is invalid")
      end

      specify "Attachment file size must be less 5 MB" do
        attach_file "track[attachment]", File.join(Rails.root, "spec", "fixtures", "audio", "up5MB.mp3")
        expect{  click_button "Save"}.to_not change{ Track.count }
        page.should have_content("Attachment file size must be less 5 MB")
      end

    end

    context "valid" do
      before{ visit "/tracks" }

      specify "should upload mp3 track" do
        expect{
          attach_file "track[attachment]", File.join(Rails.root, "spec", "fixtures", "audio", "mr_jump.mp3")
          click_button "Save"
        }.to change{ Track.count }.by(1)
        page.should have_content("Track uploaded")
      end
    end


  end

end
