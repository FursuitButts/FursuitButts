# frozen_string_literal: true

module ConfigHelper
  def number_config_field(...)
    field_tag(:number_field_tag, ...)
  end

  def text_config_field(...)
    field_tag(:text_field_tag, ...)
  end

  def large_text_config_field(...)
    field_tag(:text_area_tag, ...)
  end

  def field_tag(type, config, attribute, name: nil, bypass: false, disabled: false, hint: nil, value: config.public_send(attribute), input_options: {})
    tag.tr do
      safe_join([tag.td { label_tag(attribute, name) },
                 tag.td do
                   arr = [send(type, "config[#{attribute}]", value, disabled: disabled, **input_options)]
                   arr += [tag.br, tag.span(hint, class: "hint")] if hint
                   safe_join(arr)
                 end,
                 tag.td do
                   if bypass
                     val = config.public_send("#{attribute}_bypass")
                     select_tag("config[#{attribute}_bypass]", options_for_select(user_levels_for_select(current: val), val), disabled: disabled)
                   end
                 end,])
    end
  end

  def boolean_config_field(config, attribute, **)
    field_tag(:check_box_tag, config, attribute, input_options: { checked: config.public_send(attribute).to_s.truthy? }, **)
  end

  def object_config_field(config, attribute, name: nil, disabled: false, hint: nil)
    value = config.public_send(attribute)
    raise("#{attribute} is not a Hash") unless value.is_a?(Hash)
    tag.tr do
      safe_join([
        tag.td { label_tag("config[#{attribute}]", name) },
        tag.td do
          tag.dl do
            safe_join([value.keys.each_with_index.map do |key, _index|
              val = value[key]
              safe_join([tag.dt { label_tag("config[#{attribute}][#{key}]", key) }, tag.dd { number_field_tag("config[#{attribute}][#{key}]", val, disabled: disabled) }])
            end, tag.br, (tag.span(hint, class: "hint") if hint),])
          end
        end,
        tag.td,
      ])
    end
  end

  def user_config_field(config, attribute, name: nil, disabled: false, hint: nil)
    value = config.public_send(attribute)
    raise("#{attribute} is not a Hash") unless value.is_a?(Hash)
    tag.tr do
      safe_join([
        tag.td { label_tag("config[#{attribute}]", name) },
        tag.td do
          tag.dl do
            levels = user_levels_for_select(User::Levels::MEMBER, User::Levels::OWNER).to_a.reject { |_k, v| v == User::Levels::SYSTEM }
            safe_join([levels.each_with_index.map do |(lvl, level), _index|
              val = value[level.to_s]
              safe_join([tag.dt { label_tag("config[#{attribute}][#{level}]", lvl) }, tag.dd { number_field_tag("config[#{attribute}][#{level}]", val, disabled: disabled) }])
            end, tag.br, (tag.span(hint, class: "hint") if hint),])
          end
        end,
        tag.td,
      ])
    end
  end
end
