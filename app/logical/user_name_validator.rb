class UserNameValidator < ActiveModel::EachValidator
  def validate_each(rec, attr, value)
  	name = value

    if options[:display]
      rec.errors.add(attr, "already exists") if User.find_by(display_name: value).present?
      rec.errors.add(attr, "must be between 2 and #{Danbooru.config.display_name_max_len} characters long") unless value.length.between?(2, Danbooru.config.display_name_max_len)
      rec.errors.add(attr, "must contain only alphanumeric characters, hypens, apostrophes, tildes, underscores, and spaces") unless value =~ /\A[a-zA-Z0-9\-_~'\s]+\z/
    else
      rec.errors.add(attr, "already exists") if User.find_by(name: value).present?
      rec.errors.add(attr, "must be between 2 and #{Danbooru.config.name_max_len} characters long") unless value.length.between?(2, Danbooru.config.name_max_len)
      rec.errors.add(attr, "must contain only alphanumeric characters, hypens, apostrophes, tildes and underscores") unless value =~ /\A[a-zA-Z0-9\-_~']+\z/
    end
    rec.errors.add(attr, "must not begin with a special character") if value =~ /\A[_\-~']/
    rec.errors.add(attr, "must not contain consecutive special characters") if value =~ /_{2}|-{2}|~{2}|'{2}/
    rec.errors.add(attr, "cannot begin or end with an underscore") if value =~ /\A_|_\z/
    %w[me admin administrator].each { |name| rec.errors.add(attr, "cannot be the string \"#{name}\"") if value.downcase == name }
  end
end
