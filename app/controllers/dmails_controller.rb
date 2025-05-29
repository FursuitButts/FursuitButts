# frozen_string_literal: true

class DmailsController < ApplicationController
  respond_to(:html)
  respond_to(:json, except: %i[new create])

  def index
    @query = authorize(Dmail).html_includes(request, :from, :to, :owner)
                             .active
                             .visible
                             .for_folder(params[:folder])
                             .search(search_params(Dmail))
    @dmails = @query.paginate(params[:page], limit: params[:limit])
    respond_with(@dmails)
  end

  def show
    if params[:key].present?
      @dmail = Dmail.find_by!(id: params[:id], key: params[:key])
      authorize(Dmail) # We can't check visible with Pundit due to the key
      raise(User::PrivilegeError) unless @dmail.visible_to?(CurrentUser.user, params[:key])
    else
      @dmail = authorize(Dmail.find(params[:id]))
    end
    respond_with(@dmail) do |format|
      format.html { @dmail.mark_as_read! if CurrentUser.user == @dmail.owner }
    end
  end

  def new
    if params[:respond_to_id].present?
      parent = authorize(Dmail.find(params[:respond_to_id]), :respond?)
      @dmail = parent.build_response(forward: params[:forward])
    else
      @dmail = authorize(Dmail.new(permitted_attributes(Dmail)))
    end

    respond_with(@dmail)
  end

  def create
    authorize(Dmail.new(permitted_attributes(Dmail)))
    @dmail = Dmail.create_split(permitted_attributes(Dmail))
    respond_with(@dmail)
  end

  def destroy
    @dmail = authorize(Dmail.find(params[:id]))
    @dmail.mark_as_read!
    @dmail.update_column(:is_deleted, true)
    respond_to do |format|
      format.html { redirect_to(dmails_path, notice: "Message deleted") }
      format.json
    end
  end

  def mark_as_read
    @dmail = authorize(Dmail.find(params[:id]))
    @dmail.mark_as_read!
  end

  def mark_as_unread
    @dmail = authorize(Dmail.find(params[:id]))
    @dmail.mark_as_unread!
    respond_to do |format|
      format.html { redirect_to(dmails_path, notice: "Message marked as unread") }
      format.json
    end
  end

  def mark_all_as_read
    authorize(Dmail)
    Dmail.visible.unread.each do |x|
      x.update_column(:is_read, true)
    end
    CurrentUser.user.update(unread_dmail_count: 0)
    respond_to do |format|
      format.html { redirect_to(dmails_path, notice: "All messages marked as read") }
      format.json
    end
  end

  def mark_spam
    @dmail = authorize(Dmail.find(params[:id]))
    @dmail.mark_spam!
    notice("DMail marked as spam")
    respond_with(@dmail)
  end

  def mark_not_spam
    @dmail = authorize(Dmail.find(params[:id]))
    @dmail.mark_not_spam!
    notice("DMail marked as not spam")
    respond_with(@dmail)
  end
end
