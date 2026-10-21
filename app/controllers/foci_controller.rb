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
      redirect_to back_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Back to the cards, where the card moves into the current slot (a view transition) and its ribbon unrolls
  # (flash[:made_current]).
  def restore
    @focus.restore!
    redirect_to foci_path, flash: { made_current: true }
  end

  private

  def foci = Current.user.foci

  # Editing from a focus's notes page goes back there (?back=notes), as does Cancel; from its card, back to the cards.
  def back_path = params[:back] == "notes" ? focus_notes_path(@focus) : foci_path
  helper_method :back_path

  def set_focus = @focus = foci.find(params[:id])

  def focus_params = params.expect(focus: [ :title, :description ])
end
