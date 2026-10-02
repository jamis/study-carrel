module Admin
  class InvitationsController < ApplicationController
    before_action :require_admin

    def index
      @invitations = Invitation.includes(:created_by, :redeemed_by).newest_first
    end

    # The token exists only on the new record, so the link is carried to the next page in the
    # (encrypted) flash and never stored.
    def create
      invitation = Current.user.invitations.create!(label: params[:label].to_s.strip.presence)
      redirect_to admin_invitations_path, flash: { invitation_link: join_url(token: invitation.token), invitation_label: invitation.label }
    end

    def revoke
      Invitation.find(params[:id]).revoke!
      redirect_to admin_invitations_path
    end
  end
end
