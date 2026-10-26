# Passages the reader has kept. The ribbon in the reader talks to create / update / destroy (JSON, no body back);
# the Kept page lists them, removes one (HTML) and puts it back with Undo, remark and place in the list and all.
# Ideas, keeps with no passage, are written on the Kept page too (IdeasController).
class KeepsController < ApplicationController
  before_action :set_unit, except: :index

  # One stream, newest first: kept passages, ideas, and remarks set aside when their passage changed or went, each by
  # when it was kept.
  def index
    keeps = Current.user.keeps.preload(unit: { section: :work })
    detached = Current.user.detached_notes.where(kept: true).includes(:rich_text_content)
    @entries = (keeps + detached).sort_by { [ helpers.kept_time(it), it.id ] }.reverse
  end

  # Keeping it again (a double tap, a double-clicked Undo) changes nothing. In one transaction (SQLite's are IMMEDIATE),
  # so the second request finds the first one's keep rather than racing it into the unique index.
  def create
    Keep.transaction do
      Current.user.keeps.find_or_create_by!(unit: @unit) do |keep|
        keep.remark = params[:remark]
        keep.created_at = Keep.kept_at(params[:kept_at])
      end
    end
    request.format.json? ? head(:no_content) : redirect_to(kept_path, status: :see_other)
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def update
    keep = Current.user.keeps.find_by(unit: @unit)
    if keep.nil? || keep.update(params.expect(keep: [ :remark ]))
      head :no_content
    else
      render json: { errors: keep.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    keep = Current.user.keeps.find_by(unit: @unit)
    keep&.destroy
    if request.format.json?
      head :no_content
    else
      removed = { unit_id: @unit.id, remark: keep.remark, kept_at: keep.created_at.iso8601(6) } if keep
      redirect_to kept_path, status: :see_other, flash: { removed: }
    end
  end

  private

  def set_unit = @unit = Unit.visible_to(Current.user).find(params[:unit_id])
end
