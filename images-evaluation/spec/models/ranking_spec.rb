require "spec_helper"

describe Ranking do
  it "has a valid factory" do
    create(:ranking).should be_valid
  end
end
