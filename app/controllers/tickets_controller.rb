# frozen_string_literal: true

class TicketsController < ApplicationController
  respond_to(:html, :json, except: %i[create new])

  def index
    @tickets = authorize(Ticket).html_includes(request, :creator, :accused, :claimant, :model)
                                .search_current(search_params(Ticket))
                                .paginate(params[:page], limit: params[:limit])
    respond_with(@tickets)
  end

  def show
    @ticket = authorize(Ticket.find(params[:id]))
    respond_with(@ticket)
  end

  def new
    authorize(Ticket)
    @ticket = Ticket.new_with_current(:creator, permitted_attributes(Ticket))
    if @ticket.model_type.present? && Ticket::MODELS.types.exclude?(@ticket.model_type)
      return render_expected_error(404, "Invalid ticket type")
    end
    authorize(@ticket)
  end

  def create
    authorize(Ticket)
    @ticket = Ticket.new_with_current(:creator, permitted_attributes(Ticket))
    if @ticket.model_type.present? && Ticket::MODELS[:types].exclude?(@ticket.model_type)
      return render_expected_error(404, "Invalid ticket type")
    end
    authorize(@ticket)
    if @ticket.valid?
      @ticket.save
      @ticket.push_pubsub("create")
      notice("Ticket created")
      redirect_to(ticket_path(@ticket))
    else
      respond_with(@ticket)
    end
  end

  def update
    @ticket = authorize(Ticket.find(params[:id]))
    if @ticket.claimant_id.present? && @ticket.claimant_id != CurrentUser.user.id && !params[:force_claim].to_s.truthy?
      notice("Ticket has already been claimed by somebody else, submit again to force")
      redirect_to(ticket_path(@ticket, force_claim: "true"))
      return
    end

    ticket_params = permitted_attributes(@ticket)
    @ticket.transaction do
      if @ticket.warnable? && ticket_params[:record_type].present?
        @ticket.content.user_warned!(ticket_params[:record_type].to_i, CurrentUser.user)
      end

      @ticket.handler = CurrentUser.user
      @ticket.claimant = CurrentUser.user
      @ticket.update_with_current(:updater, ticket_params)
    end

    if @ticket.valid?
      not_changed = ticket_params[:send_update_dmail].to_s.truthy? && !@ticket.saved_change_to_response? && !@ticket.saved_change_to_status?
      notice("Not sending update, no changes") if not_changed
      @ticket.push_pubsub("update")
    end

    respond_with(@ticket)
  end

  def claim
    @ticket = authorize(Ticket.find(params[:id]))

    if @ticket.claimant.nil?
      @ticket.claim!(CurrentUser.user)
      redirect_to(ticket_path(@ticket))
      return
    end
    notice("Ticket already claimed")
    redirect_to(ticket_path(@ticket))
  end

  def unclaim
    @ticket = authorize(Ticket.find(params[:id]))

    if @ticket.claimant.nil?
      notice("Ticket not claimed")
      redirect_to(ticket_path(@ticket))
      return
    elsif @ticket.claimant.id != CurrentUser.user.id
      notice("Ticket not claimed by you")
      redirect_to(ticket_path(@ticket))
      return
    elsif @ticket.approved? || @ticket.rejected?
      notice("Cannot unclaim approved/rejected ticket")
      redirect_to(ticket_path(@ticket))
      return
    end
    @ticket.unclaim!(CurrentUser.user)
    notrice("Claim removed")
    redirect_to(ticket_path(@ticket))
  end
end
