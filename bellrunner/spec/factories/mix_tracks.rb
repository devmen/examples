# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mix_track do
    attachment { FactoryGirlExt.fixture_file_upload("spec/fixtures/audio/mr_jump.mp3", "audio/mp3")}
  end
end
