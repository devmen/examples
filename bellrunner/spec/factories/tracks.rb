# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :track do
  end

  factory :track_with_mp3, :parent => :track do
    attachment { FactoryGirlExt.fixture_file_upload("spec/fixtures/audio/mr_jump.mp3", "audio/mp3")}
  end

  factory :track_with_mp4, :parent => :track do
    attachment { FactoryGirlExt.fixture_file_upload("spec/fixtures/audio/mr_jump.mp4", "audio/mp4")}
  end

  factory :track_with_jpg, :parent => :track do
    attachment { FactoryGirlExt.fixture_file_upload("spec/fixtures/audio/mr_jump.jpg", "image/jpg")}
  end

  factory :track_with_mp3_31Mb, :parent => :track do
    attachment { FactoryGirlExt.fixture_file_upload("spec/fixtures/audio/3_1MB.mp3", "audio/mp3")}
  end


end
