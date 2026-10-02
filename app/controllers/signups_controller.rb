# Signing up with an invitation link (/join/:token).
class SignupsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, with: -> { redirect_to new_session_path, alert: "Try again later." }
  before_action :redirect_if_signed_in
  before_action :set_invitation

  def new
    @user = User.new
  end

  def create
    @user = @invitation.redeem(user_params)
    if @user.persisted?
      start_new_session_for @user
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_signed_in
    redirect_to root_path, notice: "You're already signed in." if authenticated?
  end

  def set_invitation
    @invitation = Invitation.find_redeemable(params[:token]) or render :invalid, status: :not_found
  end

  def user_params = params.expect(user: [ :email_address, :password, :password_confirmation ])
end
