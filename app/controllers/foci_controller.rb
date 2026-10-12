class FociController < ApplicationController
  before_action :set_focus, only: %i[edit update restore]

  # Home for a signed-in reader: every focus as a card, the current one first.
  def index
    @current = foci.current_one
    @past = foci.past.to_a
    return redirect_to new_focus_path if @current.nil? && @past.empty?

    @note_counts = foci.note_counts
    @works_read = foci.works_read
  end

  def new
    @focus = foci.new
    @start_keep = Current.user.keeps.find_by(unit_id: params[:unit_id]) if params[:unit_id]
  end

  def create
    @focus = foci.new(focus_params)
    @start_keep = Current.user.keeps.find_by(unit_id: params[:unit_id]) if params[:unit_id]
    if @focus.valid?
      foci.start!(focus_params.merge(last_unit: @start_keep&.unit))
      redirect_to continue_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @focus.update(focus_params)
      redirect_to foci_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def restore
    @focus.restore!
    redirect_to foci_path
  end

  private

  def foci = Current.user.foci

  def set_focus = @focus = foci.find(params[:id])

  def focus_params = params.expect(focus: [ :title, :description ])
end
