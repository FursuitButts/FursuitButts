# frozen_string_literal: true

class ConditionalRelation
  def initialize(relation, condition, truthy_value, nil_value = nil)
    @relation = relation
    @condition = condition
    @truthy_value = truthy_value
    @nil_value = nil_value
    @executed = false
  end

  def else(falsy_value)
    return @result if @executed
    return result if @condition.nil?

    @executed = true
    if @condition
      if @truthy_value.is_a?(Proc)
        @result = @relation.instance_exec(&@truthy_value)
      else
        @result = @truthy_value
      end
    elsif falsy_value.is_a?(Proc)
      @result = @relation.instance_exec(&falsy_value)
    else
      @result = falsy_value
    end

    @result
  end

  def result
    return @result if @executed

    if @condition.nil?
      if @nil_value.nil?
        @result = @relation
      elsif @nil_value.is_a?(Proc)
        @result = @relation.instance_exec(&@nil_value)
      else
        @result = @nil_value
      end
    elsif @condition
      if @truthy_value.is_a?(Proc)
        @result = @relation.instance_exec(&@truthy_value)
      else
        @result = @truthy_value
      end
    else
      @result = @relation
    end

    @executed = true
    @result
  end

  def method_missing(name, *, &)
    result.public_send(name, *, &)
  end

  def respond_to_missing?(name, include_private = false)
    result.respond_to?(name, include_private) || super
  end
end
