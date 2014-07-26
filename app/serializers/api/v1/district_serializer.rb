module Api::V1

  class DistrictSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name

    has_one :territory, serializer: TerritorySerializer

  end

end