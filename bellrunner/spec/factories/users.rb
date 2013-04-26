# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email { "guest_#{Time.now.to_i}#{rand(99)}@example.com" }
    password "password"
  end
end
