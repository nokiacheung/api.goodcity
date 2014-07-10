module Api::V1
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :item, parent: false

    # /items?ids=1,2,3,4
    def index
      if params[:ids].present?
        @items = @items.find( params[:ids].split(",") )
      end
      render json: @items, each_serializer: serializer
    end

    def create
      @item.attributes = item_params
      if @item.save
        render json: @item, serializer: serializer, status: 201
      else
        render json: @item.errors.to_json, status: 500
      end
    end

    def show
      render json: @item, serializer: serializer
    end

    def generate_cloudinary_signature
      unix_timestamp = Time.now.to_i
      secret_key = 'wQ1y_MmLsk4ShY1H4E1QpGeDhP0'
      cors_url = "http://localhost:3000/cloudinary_cors.html"
      serialized_params = "callback=#{cors_url}&timestamp=#{unix_timestamp}#{secret_key}"
      signature = Digest::SHA1.hexdigest(serialized_params)
      render json: {api_key: '457459653293635',
        callback: cors_url,
        signature: signature,
        timestamp: unix_timestamp }.to_json
    end

    private

    def serializer
      Api::V1::ItemSerializer
    end

    def item_params
      params.require(:item).permit(:donor_description, :donor_condition, :state, :offer_id,
        :item_type_id, :rejection_reason_id, :rejection_other_reason)
    end

  end
end
