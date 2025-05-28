module EditHistoryHelper
  def link_to_edit_history(input, **)
    case input
    when ForumPost
      forum_post_edits_path(input, **)
    when Comment
      comment_edits_path(input, **)
    else
      edit_histories_path(id: input.id, type: input.class.to_s, **)
    end
  end
end
