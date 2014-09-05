module Api::V1

  class DistrictSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :address_ids

    def address_ids
      object.addresses.map(&:id)
    end
  end

end
