# Putting a note on a label or taking it off, while rereading its focus. A note goes on a label by name (made if it's
# new), on one of the user's labels by id (named or not), or with another of the focus's notes found to go with it,
# making a new unnamed label of the two. The page's labels (the chips of every note on the label, the cloud and the
# tallies) are redrawn from the reply.
class NoteLabelsController < ApplicationController
  before_action :set_note
  before_action :refuse_archived_focus

  def create
    touching(@note) do
      if params[:label_id].present? then @note.join!(Current.user.labels.find(params[:label_id]))
      elsif params[:with_note_id].present? then @note.group_with!(other_note)
      else @note.label!(params[:name].to_s)
      end
    end
    render :update
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def destroy
    label = Current.user.labels.find(params[:id])
    touching(@note, label) { @note.unlabel!(label) }
    render :update
  end

  private

  # Only the reader's own focuses and notes: anyone else's is a 404.
  def set_note
    @focus = Current.user.foci.find(params[:focus_id])
    @note = @focus.notes.find(params[:note_id])
  end

  # Another note of the same focus, not this one.
  def other_note
    other = @focus.notes.find(params[:with_note_id])
    raise ActiveRecord::RecordInvalid.new(@note) if other == @note
    other
  end

  # Does the change, noting the focus's notes whose chips it may alter: those on the label before and after (an unnamed
  # label's face, seen from each of its notes, can change as notes come and go).
  def touching(note, label = nil)
    before = label ? label.note_labels.pluck(:note_id) : []
    made = yield
    label ||= made
    after = Label.exists?(label.id) ? label.note_labels.pluck(:note_id) : []
    @notes = @focus.notes.where(id: [ note.id, *before, *after ]).includes(labels: Label::FACE)
  end
end
