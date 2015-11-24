Rails.application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do
      get "browse/fetch_items" => "browse#fetch_items"
      resources :items, except: [:index]
      post "auth/signup" => "authentication#signup"
      post "auth/verify" => "authentication#verify"
      post "auth/send_pin" => "authentication#send_pin"
      post "auth/register_device" => "authentication#register_device"
      get "auth/current_user_rooms" => "authentication#current_user_rooms"
      get "auth/current_user_profile" => "authentication#current_user_profile"

      get  "districts" => "districts#index"
      get  "districts/:id" => "districts#show"
      get  "package_types" => "package_types#index"
      get  "permissions" => "permissions#index"
      get  "permissions/:id" => "permissions#show"
      get  "images/generate_signature" => "images#generate_signature"
      post "images" => "images#create"
      put  "images/:id" => "images#update"
      delete "images/:id" => "images#destroy"
      get  "messages" => "messages#index"
      get  "messages/:id" => "messages#show"
      post "messages" => "messages#create"
      put  "messages/:id" => "messages#update"
      put  "messages/:id/mark_read" => "messages#mark_read"

      get  "offers" => "offers#index"
      get  "offers/:id" => "offers#show"
      get  "offers/:id/messages" => "offers#messages"
      post "offers" => "offers#create"
      put  "offers/:id" => "offers#update"
      delete "offers/:id" => "offers#destroy"
      put  "offers/:id/review" => "offers#review"
      put  "offers/:id/complete_review" => "offers#complete_review"
      put  "offers/:id/close_offer" => "offers#close_offer"

      get  "items/:id/messages" => "items#messages"

      get  "packages" => "packages#index"
      get  "packages/:id" => "packages#show"
      post "packages" => "packages#create"
      put  "packages/:id" => "packages#update"
      delete "packages/:id" => "packages#destroy"

      get  "rejection_reasons" => "rejection_reasons#index"
      get  "rejection_reasons/:id" => "rejection_reasons#show"
      get  "territories" => "territories#index"
      get  "territories/:id" => "territories#show"
      get  "donor_conditions" => "donor_conditions#index"
      get  "donor_conditions/:id" => "donor_conditions#show"

      get  "users" => "users#index"
      get  "users/:id" => "users#show"
      put  "users/:id" => "users#update"

      post "addresses" => "addresses#create"
      get  "addresses/:id" => "addresses#show"
      post "contacts" => "contacts#create"

      post "deliveries" => "deliveries#create"
      post "confirm_delivery" => "deliveries#confirm_delivery"
      get  "deliveries/:id" => "deliveries#show"
      put  "deliveries/:id" => "deliveries#update"
      delete "deliveries/:id" => "deliveries#destroy"

      get  "schedules" => "schedules#availableTimeSlots"
      post "schedules" => "schedules#create"

      get  "gogovan_orders/driver_details" => "gogovan_orders#driver_details"
      post "gogovan_orders" => "gogovan_orders#confirm_order"
      post "gogovan_orders/calculate_price" => "gogovan_orders#calculate_price"

      get "available_dates" => "holidays#available_dates"
      get "timeslots" => "timeslots#index"
      get "gogovan_transports" => "gogovan_transports#index"
      get "crossroads_transports" => "crossroads_transports#index"
      get "versions" => "versions#index"

      post "twilio_inbound/voice" => "twilio_inbound#voice"
      post "twilio_inbound/hold_donor" => "twilio_inbound#hold_donor"
      post "twilio_inbound/accept_offer_id" => "twilio_inbound#accept_offer_id"
      post "twilio_inbound/accept_callback" => "twilio_inbound#accept_callback"
      post "twilio_inbound/send_voicemail" => "twilio_inbound#send_voicemail"
      post "twilio_inbound/assignment" => "twilio_inbound#assignment"
      get  "twilio_inbound/accept_call" => "twilio_inbound#accept_call"
      get  "twilio_inbound/hold_music" => "twilio_inbound#hold_music"
      post "twilio_inbound/call_complete" => "twilio_inbound#call_complete"
      post "twilio_inbound/call_fallback" => "twilio_inbound#call_fallback"

      post "twilio_outbound/connect_call" => "twilio_outbound#connect_call"
      post "twilio_outbound/completed_call" => "twilio_outbound#completed_call"
      post "twilio_outbound/call_status" => "twilio_outbound#call_status"
      get  "twilio_outbound/generate_call_token" =>
        "twilio_outbound#generate_call_token"

      resources :package_categories, only: [:index, :show]
    end
  end
end
