class FociController < ApplicationController
  before_action :set_focus, only: %i[edit update make_current archive unarchive delete destroy]
  before_action :refuse_archived_focus, only: %i[edit update make_current]

  # Home for a signed-in reader: every focus as a card, the current one first. Archived ones are on a page of their own.
  def index
    return redirect_to new_focus_path unless foci.exists?

    @current = foci.current_one
    @others = foci.others.to_a
    @archived_count = foci.archived.count
    @note_counts = foci.note_counts
    @works_read = foci.works_read
  end

  # The foci put away, newest first: their notes to read and export, and Unarchive.
  def archived
    @archived = foci.archived.to_a
    @note_counts = foci.note_counts
    @works_read = foci.works_read
  end

  # Started from the Kept page: a kept passage is where reading begins (unit_id), and an idea (keep_id) fills in the
  # title and description, then goes once the focus is made, its words being in the focus now.
  def new
    @start_idea = start_idea
    @focus = @start_idea ? foci.new(title: @start_idea.idea_title, description: @start_idea.idea_rest) : foci.new
    @start_keep = Current.user.keeps.find_by(unit_id: params[:unit_id]) if params[:unit_id]
  end

  def create
    @focus = foci.new(focus_params)
    @start_idea = start_idea
    @start_keep = Current.user.keeps.find_by(unit_id: params[:unit_id]) if params[:unit_id]
    if @focus.valid?
      # The idea goes only if the focus is made, so its words are never in both or neither.
      foci.transaction do
        foci.start!(focus_params.merge(last_unit: @start_keep&.unit))
        @start_idea&.destroy!
      end
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
  def make_current
    @focus.make_current!
    redirect_to foci_path, flash: { made_current: true }
  end

  # Archiving and unarchiving go back where they were done from (the cards, the archive, the notes page), with a word
  # of what happened and the way to undo it (flash[:archived] / flash[:unarchived], the focus's id). Undoing says nothing.
  def archive
    @focus.archive!
    redirect_to back_path, flash: (params[:undo] ? {} : { archived: @focus.id })
  end

  def unarchive
    @focus.unarchive!
    redirect_to back_path, flash: (params[:undo] ? {} : { unarchived: @focus.id })
  end

  # Deleting asks first on a page of its own: which focus it is, and what goes with it. An archived focus can be
  # deleted too; being read-only stops writing under it, not throwing it away.
  def delete
    @passage_notes = @focus.notes.where.not(unit_id: nil).count
    @whole_notes = @focus.notes.free.count
    @works = foci.where(id: @focus.id).works_read.fetch(@focus.id, [])
    @current = @focus == foci.current_one
    @successor = foci.others.first if @current
  end

  # No Undo: a word of it at the foot of the page it was asked from (flash[:deleted], its title, since it's gone).
  # Deleting the current focus makes the next most recent current, as if it had never been.
  # The next one is stamped current, so an archived focus that was current more recently doesn't leave none current.
  def destroy
    successor = foci.others.first if @focus == foci.current_one
    Focus.transaction do
      @focus.destroy!
      successor&.make_current!
    end
    redirect_to back_path, flash: { deleted: @focus.title }
  end

  private

  def foci = Current.user.foci

  # Editing from a focus's notes page goes back there (?back=notes), as does Cancel; from its card, back to the cards.
  # Unarchiving or deleting from the archive goes back to it (?back=archived).
  def back_path
    case params[:back]
    when "notes" then focus_notes_path(@focus)
    when "archived" then archived_foci_path
    else foci_path
    end
  end
  helper_method :back_path

  def set_focus = @focus = foci.find(params[:id])

  def start_idea = (Current.user.keeps.ideas.find_by(id: params[:keep_id]) if params[:keep_id])

  def focus_params = params.expect(focus: [ :title, :description ])
end
