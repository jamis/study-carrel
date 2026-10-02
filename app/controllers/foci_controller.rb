class FociController < ApplicationController
  before_action :set_focus, only: %i[edit update restore]

  def index
    @current = Focus.current_one
    @past = Focus.past
  end

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

  def edit
  end

  def update
    if @focus.update(focus_params)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def restore
    @focus.restore!
    redirect_to root_path
  end

  private

  def set_focus = @focus = Focus.find(params[:id])

  def focus_params = params.expect(focus: [ :title, :description ])
end
