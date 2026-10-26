# Ideas: keeps with no passage, something to study someday, jotted and edited on the Kept page. Removing one goes back
# there with Undo, which posts it again with its words and its place in the stream (kept_at).
class IdeasController < ApplicationController
  before_action :set_idea, only: %i[update destroy]

  def create
    Current.user.keeps.ideas.create(remark: params.dig(:keep, :remark), created_at: Keep.kept_at(params[:kept_at]))
    redirect_to kept_path, status: :see_other
  end

  # Emptying an idea, or making it too long, leaves it as it was: Remove is the way to be rid of one.
  def update
    @idea.update(params.expect(keep: [ :remark ]))
    redirect_to kept_path, status: :see_other
  end

  def destroy
    @idea.destroy!
    redirect_to kept_path, status: :see_other, flash: { removed_idea: { remark: @idea.remark, kept_at: @idea.created_at.iso8601(6) } }
  end

  private

  def set_idea = @idea = Current.user.keeps.ideas.find(params[:id])
end
