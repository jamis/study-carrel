# A user's own texts (see UserText): listed on Your Texts, added through new > review > create, deleted while nothing
# is attached to them. Only the owner ever reaches one.
class UserTextsController < ApplicationController
  def index
    @texts = Current.user.texts.to_a
    @sentence_counts = Unit.joins(:section).where(sections: { work_id: @texts }).group("sections.work_id").count
  end

  def new
    @text = UserText.new
  end

  # How the text will be read, before anything is saved. "Edit the text" comes back here with edit=1.
  def review
    @text = UserText.new(text_params)
    if params[:edit]
      render :new
    elsif @text.invalid?
      render :new, status: :unprocessable_content
    end
  end

  def create
    @text = UserText.new(text_params)
    return render(:new, status: :unprocessable_content) if @text.invalid?

    work = @text.publish!(Current.user)
    redirect_to reading_path(work.slug, 1, 1)
  end

  # Until notes can be set aside (detached), a text with notes or keeps on it stays.
  def destroy
    work = Current.user.texts.find_by!(slug: params[:slug])
    if work.annotated?
      redirect_to texts_path, alert: "“#{work.title}” has notes or kept passages, so it can’t be deleted yet."
    else
      work.remove!
      redirect_to texts_path, notice: "Deleted “#{work.title}”."
    end
  end

  private

  def text_params = params.expect(user_text: %i[title author source])
end
