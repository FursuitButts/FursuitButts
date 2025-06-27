# frozen_string_literal: true

class UserResolvableSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize(arg)
    super("user" => arg.user&.id, "ip_addr" => arg.ip_addr)
  end

  def deserialize(arg)
    UserResolvable.new(arg["user"].blank? ? nil : User.find(arg["user"]), arg["ip_addr"])
  end

  private

  def klass
    UserResolvable
  end
end
