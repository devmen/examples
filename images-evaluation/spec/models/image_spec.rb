require 'spec_helper'

describe Image do
  it "has a valid factory" do
    create(:image).should be_valid
  end

  describe "#average_rank" do
    context "when image not ranked yet" do
      before { @image = create(:image) }
      it "return nil" do
        @image.average_rank.should be_nil
      end
    end

    context "when image ranked 3, 4 and 5" do
      before do
        @image = create(:image)
        [3, 4, 5].each do |rating|
          create(:ranking, image_id: @image.id, rating: rating)
        end
      end

      it "return 4" do
        @image.average_rank.should == 4
      end
    end

    context "when image ranked 3, 3, 5" do
      before do
        @image = create(:image)
        [3, 3, 5].each do |rating|
          create(:ranking, image_id: @image.id, rating: rating)
        end
      end

      it "return 3.67" do
        @image.average_rank.should == 4
      end
    end
  end

  describe ".average_rank" do
    context "when photos not ranked yet" do
      before do
        2.times { create(:image) }
      end

      it "return zero" do
        Image.average_rank.should be_zero
      end
    end

    context "when photos ranked" do
      before do
        @image1 = create(:image)
        3.times { |i|
          create(:ranking, image_id: @image1.id, rating: i + 3)
        }
        @image2 = create(:image)
        3.times { |i|
          create(:ranking, image_id: @image2.id, rating: i + 1)
        }
      end

      it "should return 3" do
        Image.average_rank.should == 3
      end
    end
  end
end
