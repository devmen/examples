
FactoryGirl.define do
  factory :image do
    sequence(:url) { |n| "photo_#{n}.jpg" }
  end
end
