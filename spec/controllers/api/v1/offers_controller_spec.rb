require 'rails_helper'

RSpec.describe Api::V1::OffersController, type: :controller do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  let(:user) { create(:user_with_token) }
  let(:reviewer) { create(:user, :with_can_manage_offers_permission, role_name: 'Reviewer') }
  let(:supervisor) { create(:user, :with_can_manage_offers_permission, role_name: 'Supervisor') }
  let(:offer) { create(:offer, :with_transport, created_by: user) }
  let(:submitted_offer) { create(:offer, created_by: user, state: 'submitted') }
  let(:in_review_offer) { create(:offer, created_by: user, state: 'under_review', reviewed_by: reviewer) }
  let(:serialized_offer) { Api::V1::OfferSerializer.new(offer) }
  let(:serialized_offer_json) { JSON.parse( serialized_offer.to_json ) }
  let(:allowed_params) { [:language, :origin, :stairs, :parking, :estimated_size, :notes] }
  let(:offer_params) { FactoryGirl.attributes_for(:offer).tap{|attrs| (attrs.keys - allowed_params).each{|a| attrs.delete(a)} } }

  describe "GET offers" do
    before { generate_and_set_token(reviewer) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized offers", :show_in_doc do
      2.times{ create :offer }
      get :index
      body = JSON.parse(response.body)
      expect( body['offers'].length ).to eq(2)
    end

    context "exclude_messages" do
      it "is 'false'" do
        offer1 = create(:offer, :with_messages)
        expect(offer1.messages.size).to eql(1)
        get :index, exclude_messages: "false"
        expect(assigns(:offers).to_a).to eql([offer1])
        expect(response.body).to include(offer1.messages.first.body)
      end

      it "is 'true'" do
        offer1 = create(:offer, :with_messages)
        expect(offer1.messages.size).to eql(1)
        get :index, exclude_messages: "true"
        expect(assigns(:offers).to_a).to eql([offer1])
        expect(response.body).to_not include(offer1.messages.first.body)
      end

      it "is not set" do
        offer1 = create(:offer, :with_messages)
        expect(offer1.messages.size).to eql(1)
        get :index
        expect(assigns(:offers).to_a).to eql([offer1])
        expect(response.body).to include(offer1.messages.first.body)
      end
    end
    context "states" do
      it "returns offers in the submitted state" do
        offer1 = create(:offer, state: "submitted")
        offer2 = create(:offer, state: "draft")
        get :index, states: ["submitted"]
        expect(assigns(:offers).to_a).to eql([offer1])
      end

      it "returns offers in the active states" do
        offer1 = create(:offer, state: "draft")
        offer2 = create(:offer, state: "closed")
        get :index, states: ["active"]
        subject = assigns(:offers).to_a
        expect(subject).to include(offer1)
        expect(subject).to_not include(offer2)
      end

      it "returns offers in all states (default)" do
        offer1 = create(:offer, state: "draft")
        offer2 = create(:offer, state: "closed")
        get :index
        subject = assigns(:offers).to_a
        expect(subject).to include(offer1)
        expect(subject).to include(offer2)
      end
    end

    context "created_by_id" do
      it "returns offers created by this user" do
        offer1 = create(:offer)
        offer2 = create(:offer)
        get :index, created_by_id: offer1.created_by_id
        expect(assigns(:offers).to_a).to eql([offer1])
      end

      describe "if user is supervisor" do
        context "for donor app"
          let!(:offer1) { create :offer, created_by: supervisor }
          let!(:offer2) { create :offer }
          before { generate_and_set_token(supervisor) }

          it 'returns offers created_by supervisor' do
            request.headers["X-GOODCITY-APP-NAME"] = "app.goodcity"
            get :index
            expect(assigns(:offers).to_a).to eql([offer1])
            expect(assigns(:offers).to_a).not_to include(offer2)
            expect(assigns(:offers).count).to eq(1)
          end
        end

        context "for admin app" do
          let!(:offer1) { create :offer, created_by: supervisor }
          let!(:offer2) { create :offer }
          before { generate_and_set_token(supervisor) }

          it "returns all offers" do
            request.headers["X-GOODCITY-APP-NAME"] = "admin.goodcity"
            get :index
            expect(assigns(:offers).to_a).to include(offer1)
            expect(assigns(:offers).to_a).to include(offer2)
            expect(assigns(:offers).to_a.count).to eq(2)
          end
        end
    end

    context "reviewed_by_id" do
      it "returns offers reviewed by this user" do
        offer1 = create(:offer, reviewed_by: user)
        offer2 = create(:offer)
        get :index, reviewed_by_id: offer1.reviewed_by_id
        expect(assigns(:offers).to_a).to eql([offer1])
      end
    end
  end

  describe "GET offer/1" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      get :show, id: offer.id
      expect(response.status).to eq(200)
    end
  end

  describe "POST offer/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      post :create, offer: offer_params
      expect(response.status).to eq(201)
    end
  end

  describe "PUT offer/1" do
    context "owner" do
      before { generate_and_set_token(user) }
      it "owner can submit", :show_in_doc do
        extra_params = { state_event: 'submit', saleable: true}
        expect(offer).to be_draft
        put :update, id: offer.id, offer: offer_params.merge(extra_params)
        expect(response.status).to eq(200)
        expect(offer.reload).to be_submitted
      end
    end
  end

  describe "PUT offer/1/review" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can review", :show_in_doc do
        expect(submitted_offer).to be_submitted
        put :review, id: submitted_offer.id
        expect(response.status).to eq(200)
        expect(submitted_offer.reload).to be_under_review
      end
    end
  end

  describe "PUT offer/1/complete_review" do
    let(:gogovan_transport) { create :gogovan_transport }
    let(:crossroads_transport) { create :crossroads_transport }

    let(:offer_attributes) {
      { state_event: "finish_review",
        gogovan_transport_id: gogovan_transport.id,
        crossroads_transport_id: crossroads_transport.id }
    }

    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can complete review", :show_in_doc do
        expect(in_review_offer).to be_under_review
        put :complete_review, id: in_review_offer.id, offer: offer_attributes, complete_review_message: "test"
        expect(response.status).to eq(200)
        expect(in_review_offer.reload).to be_reviewed
        expect(in_review_offer.crossroads_transport).to eq(crossroads_transport)
      end
    end
  end

  describe "PUT offer/1/close_offer" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can close offer", :show_in_doc do
        expect(in_review_offer).to be_under_review
        expect {
          put :close_offer, id: in_review_offer.id, complete_review_message: "test"
          }.to change(in_review_offer.messages, :count).by(1)
        expect(response.status).to eq(200)
        expect(in_review_offer.reload).to be_closed
      end
    end
  end

  describe "PUT offer/1/receive_offer" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can close offer", :show_in_doc do
        expect(in_review_offer).to be_under_review
        expect {
          put :receive_offer, id: in_review_offer.id, close_offer_message: "test"
        }.to change(in_review_offer.messages, :count).by(1)
        expect(response.status).to eq(200)
        expect(in_review_offer.reload).to be_received
      end
    end
  end

  describe "PUT offer/1/merge_offer" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }

      let(:donor) { create :user }
      let(:merge_offer) { create :offer, :submitted, :with_items, created_by: donor }
      let(:base_offer) { create :offer, :submitted, :with_items, created_by: donor }
      let(:scheduled_offer) { create :offer, :scheduled, :with_items, created_by: donor }

      it "can merge offer", :show_in_doc do
        put :merge_offer, id: merge_offer.id, base_offer_id: base_offer.id
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["status"]).to eq(true)
        expect{
          Offer.find(merge_offer.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "can not merge offer when scheduled", :show_in_doc do
        put :merge_offer, id: scheduled_offer.id, base_offer_id: base_offer.id
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["status"]).to eq(false)
      end
    end
  end

  describe "DELETE offer/1" do
    context "donor" do
      before { generate_and_set_token(user) }
      it "returns 200", :show_in_doc do
        delete :destroy, id: offer.id
        expect(response.status).to eq(200)
        body = JSON.parse(response.body)
        expect(body).to eq( {} )
      end
    end

    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can delete offer", :show_in_doc do
        delete :destroy, id: in_review_offer.id
        expect(response.status).to eq(200)
        body = JSON.parse(response.body)
        expect(body).to eq( {} )
      end
    end
  end
end
