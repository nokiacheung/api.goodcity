FactoryGirl.define do
  factory :organisation do
    name_en { FFaker::Company.name }
    name_zh_tw { FFaker::Company.name }
    description_en ["Mr. Johnson and Mr. Smith both have left their respective  jobs in order to specialize in environmental engineering consulting to small and medium sized businesses.",
        "Mr Johnson's previous employment was with Randolf and Associates
         acting as an environmental engineer.",
         "Mr. Smith's previous employment was with Barnard and Barry
          Environmental acting as chief environmental engineer."].sample

    description_zh_tw ["Mr. Johnson and Mr. Smith both have left their respective  jobs in order to specialize in environmental engineering consulting to small and medium sized businesses.",
        "Mr Johnson's previous employment was with Randolf and Associates
         acting as an environmental engineer.",
         "Mr. Smith's previous employment was with Barnard and Barry
          Environmental acting as chief environmental engineer."].sample

    registration { (rand(89)+10).to_s+"/"+(rand(10000)+10000).to_s }
    website FFaker::Internet.http_url
    association :country
    association :district
    association :organisation_type
  end
end
