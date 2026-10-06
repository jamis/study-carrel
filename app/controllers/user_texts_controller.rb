# A user's own texts (see UserText): listed on Your Texts, added through new > review > create, revised through
# edit > review > update (see TextRevision), and deleted. Notes and remarked keeps on sentences that a revision or a
# deletion takes away are set aside as detached notes. Only the owner ever reaches a text.
class UserTextsController < ApplicationController
  before_action :set_work, only: %i[edit update destroy]

  def index
    @texts = Current.user.texts.to_a
    units = Unit.joins(:section).where(sections: { work_id: @texts })
    @unit_counts = units.group("sections.work_id").count
    @annotation_counts = Note.joins(unit: :section).merge(units).group("sections.work_id").count
                             .merge(Keep.joins(unit: :section).merge(units).group("sections.work_id").count) { |_, a, b| a + b }
  end

  def new
    @text = UserText.new
  end

  def edit
    @text = UserText.new(title: @work.title, author: @work.author, source: @work.source, form: UserText.form_of(@work))
    render :new
  end

  # How the text will be read (and, for a revision, what happens to its notes), before anything is saved. "Edit the
  # text" comes back here with edit=1.
  def review
    @work = Current.user.texts.find_by!(slug: params[:slug]) if params[:slug]
    @text = UserText.new(text_params)
    if params[:edit]
      render :new
    elsif @text.invalid?
      render :new, status: :unprocessable_content
    else
      @revision = TextRevision.new(@work, @text) if @work
    end
  end

  def create
    @text = UserText.new(text_params)
    return render(:new, status: :unprocessable_content) if @text.invalid?

    work = @text.publish!(Current.user)
    redirect_to reading_path(work.slug, 1, 1)
  end

  def update
    @text = UserText.new(text_params)
    return render(:new, status: :unprocessable_content) if @text.invalid?

    detached = set_aside_count { TextRevision.new(@work, @text).apply! }
    redirect_to texts_path, notice: "Saved “#{@work.title}”.#{set_aside_message(detached)}"
  end

  def destroy
    detached = set_aside_count do
      DetachedNote.set_aside!(Unit.joins(:section).where(sections: { work_id: @work.id }), reason: "deleted")
      @work.remove!
    end
    redirect_to texts_path, notice: "Deleted “#{@work.title}”.#{set_aside_message(detached)}"
  end

  private

  def set_work = @work = Current.user.texts.find_by!(slug: params[:slug])

  # A revision keeps the text's form, whatever is posted: changing it would change every unit's shape.
  def text_params
    attrs = params.expect(user_text: %i[title author source form])
    @work ? attrs.merge(form: UserText.form_of(@work)) : attrs
  end

  def set_aside_count
    before = Current.user.detached_notes.count
    yield
    Current.user.detached_notes.count - before
  end

  def set_aside_message(count)
    " #{count == 1 ? "One note was" : "#{count} notes were"} set aside with the passages they were written on." if count.positive?
  end
end
