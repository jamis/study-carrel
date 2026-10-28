# Naming a label from the reread: giving an unnamed group of notes words, renaming a label, or taking its name away
# (leaving it known by its example). A name the user already has for another label is refused, with why; the two
# aren't merged. Asked from Compare's card, or from the band while rereading the label. The labels on the focus's page
# are redrawn from the reply.
class LabelsController < ApplicationController
  before_action :set_focus, :refuse_archived_focus

  def update
    label = Current.user.labels.find(params[:id])
    label.rename!(params[:name].to_s)
    @renamed = label
    @notes = @focus.notes.where(id: label.note_labels.select(:note_id)).includes(labels: Label::FACE)
    render "note_labels/update"
  rescue ActiveRecord::RecordInvalid
    render plain: refusal(label), status: :unprocessable_entity
  end

  private

  def set_focus = @focus = Current.user.foci.find(params[:focus_id])

  def refusal(label)
    if label.errors.of_kind?(:name, :taken) then "You already have a label called “#{label.name}”."
    else "A name is at most 40 characters."
    end
  end
end
