module Api
  module V1
    class RejectionReasonsController < Api::V1::ApiController
      load_and_authorize_resource :rejection_reason, parent: false

      def index
        render_object_with_cache(@rejection_reasons, params[:ids])
      end

      def show
        render json: @rejection_reason, serializer: serializer
      end

      private

      def serializer
        Api::V1::RejectionReasonSerializer
      end
    end
  end
end
