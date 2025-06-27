# frozen_string_literal: true

def u2id(value, klass = User)
  value.is_a?(klass) || (klass == User && value.is_a?(UserResolvable)) ? value.id : value
end
