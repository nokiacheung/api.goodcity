# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    order 1
    image { Faker::Lorem.characters(10) }
    favourite false
    association :parent
  end
end
