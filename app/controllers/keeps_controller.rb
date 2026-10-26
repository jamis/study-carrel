# Passages the reader has kept. The ribbon in the reader talks to create / update / destroy (JSON, no body back);
# the Kept page lists them, removes one (HTML) and puts it back with Undo, remark and place in the list and all.
class KeepsController < ApplicationController
  before_action :set_unit, except: :index

  def index
    keeps = Current.user.keeps.preload(unit: { section: :work })
    @keeps = if params[:order] == "reading"
      keeps.joins(unit: :section).in_order_of(:"sections.work_id", Work.ids_in_library_order).order("sections.number", "units.number")
    else
      keeps.order(created_at: :desc, id: :desc)
    end
    @detached = Current.user.detached_notes.where(kept: true).includes(:rich_text_content)
  end

  def create
    Current.user.keeps.find_or_create_by!(unit: @unit) do |keep|
      keep.remark = params[:remark]
      keep.created_at = kept_at
    end
    request.format.json? ? head(:no_content) : redirect_to(kept_list_path, status: :see_other)
  rescue ActiveRecord::RecordNotUnique
    head :no_content
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
      redirect_to kept_list_path, status: :see_other, flash: { removed: }
    end
  end

  private

  def set_unit = @unit = Unit.visible_to(Current.user).find(params[:unit_id])

  # Undo puts a keep back where it was in the newest-first list; anything else is kept now.
  def kept_at
    Time.iso8601(params[:kept_at]).clamp(..Time.current) if params[:kept_at]
  rescue ArgumentError
    nil
  end

  # Back to the Kept page in the order it was in.
  def kept_list_path = kept_path(order: ("reading" if params[:order] == "reading"))
end
