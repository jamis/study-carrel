class FociController < ApplicationController
  def new
    @focus = Focus.new
  end

  def create
    @focus = Focus.new(focus_params)
    if @focus.valid?
      Focus.start!(focus_params)
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def focus_params = params.expect(focus: [ :title, :description ])
end
