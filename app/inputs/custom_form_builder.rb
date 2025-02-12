# frozen_string_literal: true

class CustomFormBuilder < SimpleForm::FormBuilder
  def policy
    @policy ||= @options[:policy]
  end

  def policy_action
    @policy_action ||= @options[:policy_action] || lookup_action
  end

  def input(attribute_name, options = {}, &)
    ipolicy = options.delete(:policy)
    if ipolicy != false && (ipolicy || policy).present? && !(ipolicy || policy).can_use_attribute?(attribute_name, policy_action)
      return "".html_safe
    end
    options = insert_autocomplete(options)
    super
  end

  include FormBuilderCommon
end
