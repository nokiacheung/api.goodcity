require 'rails_helper'

RSpec.describe Purpose, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :order }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:name_en).of_type(:string)}
    it{ is_expected.to have_db_column(:name_zh_tw).of_type(:string)}
  end
end
