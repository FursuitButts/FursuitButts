# frozen_string_literal: true

module BulkUpdateRequestCommands
  class MassUpdate < Base
    set_command(:mass_update)
    set_arguments(:antecedent_query, :consequent_query, :comment)
    set_regex(/\A(?:mass update|update) ([^#]+?) -> ([^#]*)(?: # ?(.*))?\z/i, %i[query query pass])
    set_untokenize { |antecedent_query, consequent_query, comment| "update #{antecedent_query} -> #{consequent_query}#{" # #{comment}" if comment}" }
    set_to_dtext { |antecedent_query, consequent_query, comment| "update {{#{antecedent_query}}} (#{Post.fast_count(antecedent_query, enable_safe_mode: false, include_deleted: true)}) -> {{#{consequent_query}}}#{" # #{comment}" if comment}" }

    validate(:antecedent_query_valid)
    validate(:consequent_query_valid)

    def antecedent_query_valid
      begin
        TagQuery.new(antecedent_query)
      rescue TagQuery::CountExceededError
        errors.add(:base, "antecedent query exceeds the maximum tag count")
      end
      errors.add(:base, "antecedent query is not simple") if TagQuery.has_any_metatag?(antecedent_query)
    end

    def consequent_query_valid
      begin
        TagQuery.new(consequent_query)
      rescue TagQuery::CountExceededError
        errors.add(:base, "consequent query exceeds the maximum tag count")
      end
      errors.add(:base, "consequent query is not simple") if TagQuery.has_any_metatag?(consequent_query)
    end

    def estimate_update_count
      return 0 unless valid?
      Post.fast_count(antecedent_query, enable_safe_mode: false, include_deleted: true)
    end

    def tags
      TagQuery.scan(antecedent_query)
    end

    def process(_processor, approver)
      ensure_valid!
      CurrentUser.scoped(approver) do
        ModAction.log!(:mass_update, nil, antecedent: antecedent_query, consequent: consequent_query)
        Post.tag_match_sql(antecedent_query).reorder(nil).parallel_find_each do |post|
          post.with_lock do
            post.automated_edit = true
            post.tag_string += " #{consequent_query}"
            post.save
          end
        end
      end
    end
  end
end
