# frozen_string_literal: true

class HelpController < ApplicationController
  respond_to(:html, :json)
  helper(WikiPagesHelper)

  def index
    @help_pages = authorize(HelpPage).help_index
    respond_with(@help_pages)
  end

  def show
    if params[:id] =~ /\A\d+\Z/
      @help = HelpPage.find(params[:id])
    else
      @help = HelpPage.find_by(name: params[:id])
    end
    authorize(@help, policy_class: HelpPagePolicy)
    if @help.blank?
      respond_to do |format|
        format.html { redirect_to(help_pages_path, notice: "The help page \"#{params[:id]}\" was not found") }
        format.json { raise(ActiveRecord::RecordNotFound) }
      end
      return
    end
    if @help.wiki_page.parent.present?
      @wiki_redirect = WikiPage.find_by(title: @help.wiki_page.parent_name)
    end
    respond_with(@help)
  end

  def new
    @help = authorize(HelpPage.new(permitted_attributes(HelpPage)))
    respond_with(@help)
  end

  def edit
    @help = authorize(HelpPage.find(params[:id]))
    respond_with(@help)
  end

  def create
    @help = authorize(HelpPage.new(permitted_attributes(HelpPage)))
    @help.save
    notice(@help.valid? ? "Help page created" : @help.errors.full_messages.join("; "))
    respond_with(@help)
  end

  def update
    @help = authorize(HelpPage.find(params[:id]))
    @help.update(permitted_attributes(@help))
    notice(@help.errors.any? ? @help.errors.full_messages.join("; ") : "Help page updated")
    respond_with(@help)
  end

  def destroy
    @help = authorize(HelpPage.find(params[:id]))
    @help.destroy
    respond_with(@help)
  end
end
