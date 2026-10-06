# Passages the reader has kept. The ribbon in the reader talks to create / update / destroy (JSON, no body back);
# the Kept page lists them.
class KeepsController < ApplicationController
  before_action :set_unit, except: :index

  def index
    keeps = Current.user.keeps.preload(unit: { section: :work })
    @keeps = if params[:order] == "reading"
      keeps.joins(unit: :section).in_order_of(:"sections.work_id", Work.ids_in_library_order).order("sections.number", "units.number")
    else
      keeps.order(created_at: :desc, id: :desc)
    end
    @has_focus = Current.user.foci.current.exists?
    @detached = Current.user.detached_notes.where(kept: true).includes(:rich_text_content)
  end

  def create
    Current.user.keeps.find_or_create_by!(unit: @unit)
    head :no_content
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
    Current.user.keeps.where(unit: @unit).destroy_all
    request.format.json? ? head(:no_content) : redirect_to(kept_path, status: :see_other)
  end

  private

  def set_unit = @unit = Unit.visible_to(Current.user).find(params[:unit_id])
end
