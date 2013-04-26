require 'spec_helper'

describe 'Required tools' do

  context "mp3splt (version 2.4.3)" do
    specify "should be installed" do
      lambda{
        (Cocaine::CommandLine.new('mp3splt -v').run.match(/mp3splt(.*)\(/) && $1).strip.should eq("2.4.3")
      }.should_not raise_error(Cocaine::ExitStatusError)

    end
  end

  context "sox" do
    specify "should be installed" do
      lambda{
        Cocaine::CommandLine.new('which', SOX_CONFIG[:command]).run
      }.should_not raise_error(Cocaine::ExitStatusError)

    end
  end

  context "soxi" do
    specify "should be installed" do
      lambda{
        Cocaine::CommandLine.new('which', SOX_CONFIG[:soxi_command]).run
      }.should_not raise_error(Cocaine::ExitStatusError)

    end
  end
end
