FactoryGirl.define do
  factory :purpose do
    name_en { FFaker::Lorem.word }
    name_zh_tw { FFaker::Lorem.word }
  end
end
