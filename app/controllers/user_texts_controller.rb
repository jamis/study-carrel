# A user's own texts (see UserText): listed on Your Texts, added through new > review > create, revised through
# edit > review > update (see TextRevision), and deleted. Notes and remarked keeps on sentences that a revision or a
# deletion takes away are set aside as detached notes. Only the owner ever reaches a text.
class UserTextsController < ApplicationController
  include SetsAsideNotes

  before_action :set_work, only: %i[edit update destroy]
  # Matching a revision can take a couple of seconds (see TextRevision). Only that is limited: reviewing a new text or
  # going back to edit one doesn't match anything.
  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }, only: %i[review update], with: -> { slow_down },
             if: -> { params[:slug] && !params[:edit] }

  # The user's collections, then their texts in none.
  def index
    @collections = Current.user.collections.top_level.to_a
    @work_counts = Current.user.collections.work_counts
    @any_texts = Current.user.texts.exists?
    @texts = Current.user.texts.where(collection_id: nil).to_a
    units = Unit.joins(:section).where(sections: { work_id: @texts })
    @unit_counts = units.group("sections.work_id").count
    @annotation_counts = Note.joins(unit: :section).merge(units).group("sections.work_id").count
                             .merge(Keep.joins(unit: :section).merge(units).group("sections.work_id").count) { |_, a, b| a + b }
  end

  # From a collection's "Add a text here", the text goes into that collection unless the form says otherwise.
  def new
    @text = UserText.new(collection_id: Current.user.collections.find_by(slug: params[:collection])&.id)
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
    redirect_to reading_path(work.slug, 1, work.sections.first.units.first.number)
  end

  def update
    @text = UserText.new(text_params)
    return render(:new, status: :unprocessable_content) if @text.invalid?

    @revision = TextRevision.new(@work, @text)
    return render(:review, status: :unprocessable_content) if @revision.too_different?

    detached = set_aside_count { @revision.apply! }
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

  # A revision keeps the text's form, whatever is posted: changing it would change every unit's shape. It stays in its
  # collection, too: only a new text is put in one.
  def text_params
    attrs = params.expect(user_text: %i[title author source form collection_id])
    @work ? attrs.merge(form: UserText.form_of(@work)).except(:collection_id) : attrs
  end

  # The form back, with the text as it was sent.
  def slow_down
    @work ||= Current.user.texts.find_by!(slug: params[:slug])
    @text = UserText.new(text_params)
    @text.errors.add(:base, "That’s a lot of revising in a minute: wait a moment, then try again")
    render :new, status: :too_many_requests
  end
end
