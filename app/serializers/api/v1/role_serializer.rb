module Api::V1
  class RoleSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :name

    has_many :role_permissions, serializer: RolePermissionSerializer
  end
end