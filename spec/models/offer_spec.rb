require "rails_helper"

RSpec.describe Offer, type: :model do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  let(:offer) { create :offer }

  it_behaves_like "paranoid"

  describe "Associations" do
    it { is_expected.to belong_to :created_by }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_many :items }
  end

  describe "Database Columns" do
    it { is_expected.to have_db_column(:language).of_type(:string) }
    it { is_expected.to have_db_column(:state).of_type(:string) }
    it { is_expected.to have_db_column(:origin).of_type(:string) }
    it { is_expected.to have_db_column(:stairs).of_type(:boolean) }
    it { is_expected.to have_db_column(:parking).of_type(:boolean) }
    it { is_expected.to have_db_column(:estimated_size).of_type(:string) }
    it { is_expected.to have_db_column(:notes).of_type(:text) }
    it { is_expected.to have_db_column(:created_by_id).of_type(:integer) }

    it { is_expected.to have_db_column(:submitted_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:reviewed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:review_completed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:received_at).of_type(:datetime) }
  end

  describe "validations" do
    it do
      is_expected.to validate_inclusion_of(:language).
        in_array( I18n.available_locales.map(&:to_s) )
    end
  end

  it "should set submitted_at when submitted" do
    expect( offer.submitted_at ).to be_nil
    offer.update_attributes(state_event: "submit")
    expect( offer.submitted_at ).to_not be_nil
  end

  describe "Class Methods" do
    describe "valid_state?" do
      it "should verify state valid or not" do
        expect(Offer.valid_state?("submitted")).to be true
        expect(Offer.valid_state?("submit")).to be false
      end
    end

    describe "valid_states" do
      it "should return list of valid states" do
        expect(Offer.valid_states).to include("draft")
        expect(Offer.valid_states).to include("submitted")
      end
    end
  end

  describe 'assign_reviewer' do
    it 'should assign reviewer to offer' do
      reviewer = create(:user, :reviewer)
      offer = create :offer, :submitted
      expect{
        offer.assign_reviewer(reviewer)
      }.to change(offer, :reviewed_at)
      expect(offer.reviewed_by).to eq(reviewer)
    end
  end

  describe 'offer state change time attributes' do
    it 'should set submitted_at' do
      offer = create :offer, state: 'draft'
      expect{ offer.submit }.to change(offer, :submitted_at)
    end

    it 'should set reviewed_at' do
      offer = create :offer, :submitted
      expect{ offer.start_review }.to change(offer, :reviewed_at)
    end

    it 'should set review_completed_at' do
      offer = create :offer, :under_review
      expect{ offer.finish_review }.to change(offer, :review_completed_at)
    end

    it 'should set received_at' do
      offer = create :offer, :scheduled
      expect{ offer.receive }.to change(offer, :received_at)
    end
  end

  describe 'scope' do
    let!(:closed_offer) { create :offer, :closed }
    let!(:received_offer) { create :offer, :received }
    let!(:submitted_offer) { create :offer, :submitted }

    it 'active' do
      active_offers = Offer.active
      expect(active_offers).to include(submitted_offer)
      expect(active_offers).to_not include(closed_offer)
      expect(active_offers).to_not include(received_offer)
      expect(scrub(Offer.active.to_sql)).to include(
        "state NOT IN ('received','closed')")
    end

    it 'inactive' do
      inactive_offers = Offer.inactive
      expect(inactive_offers).to_not include(submitted_offer)
      expect(inactive_offers).to include(closed_offer)
      expect(inactive_offers).to include(received_offer)
      expect(scrub(Offer.inactive.to_sql)).to include(
        "deleted_at IS NOT NULL OR state IN ('received','closed')")
    end

    describe "review_by" do
      it "should return offers reviewed by current reviewer" do
        reviewer = create :user, :reviewer
        offer = create :offer, reviewed_by: reviewer
        expect(Offer.review_by(reviewer.id)).to include(offer)
      end
    end

    describe "created_by" do
      it "should return offers donated by specific donor" do
        donor = create :user
        offer = create :offer, created_by: donor
        expect(Offer.created_by(donor.id)).to include(offer)
      end
    end
  end

  describe "#send_thank_you_message" do
    it 'should send thank you message to donor on offer submit' do
      offer = create :offer
      offer.submit
      expect(offer.messages.count).to eq(1)
      expect(offer.messages.last.sender).to eq(User.system_user)
    end
  end

  describe "#send_new_offer_alert" do
    let(:user)  { build(:user) }
    let(:offer) { create(:offer) }
    let(:new_offer_alert_mobiles) { "+85252345678, +85261234567" }
    let(:twilio) { TwilioService.new(user) }

    it 'should send new offer alert SMS' do
      ENV['NEW_OFFER_ALERT_MOBILES'] = new_offer_alert_mobiles
      allow(offer).to receive(:send_thank_you_message) # bypass this
      expect(User).to receive(:where).with(mobile: new_offer_alert_mobiles.split(",").map(&:strip)).and_return([user])
      expect(TwilioService).to receive(:new).with(user).and_return(twilio)
      expect(twilio).to receive(:new_offer_alert).with(offer)
      offer.submit
    end

    it 'should not send alert if NEW_OFFER_ALERT_MOBILES is blank' do
      ENV['NEW_OFFER_ALERT_MOBILES'] = ""
      allow(offer).to receive(:send_thank_you_message) # bypass this
      expect(TwilioService).to_not receive(:new)
      offer.submit
    end
  end

  describe "#send_ggv_cancel_order_message" do
    let!(:delivery) { create :gogovan_delivery, offer: offer }
    let!(:time_string) { delivery.schedule.formatted_date_and_slot }
    let(:subject) { offer.messages.last }

    it 'should send GGV cancel message to donor' do
      expect{
        offer.send_ggv_cancel_order_message
      }.to change(offer.messages, :count).by(1)
      expect(subject.sender).to eq(User.system_user)
      expect(subject.body).to eq("A van booking for #{time_string} was cancelled via GoGoVan. Please choose new transport arrangements.")
    end
  end

  describe 'close offer' do
    let(:offer) { create :offer, state: 'scheduled' }
    let!(:delivery) { create :gogovan_delivery, offer: offer }
    it 'should cancel GoGoVan booking' do
      expect(Gogovan).to receive(:cancel_order).with(delivery.gogovan_order.booking_id)
      expect(delivery.gogovan_order.status).to eq('pending')
      offer.close!
      expect(delivery.gogovan_order.status).to eq('cancelled')
    end
  end
end
