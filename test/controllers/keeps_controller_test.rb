require "test_helper"

class KeepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @user = users(:one)
    @user.foci.start!(title: "Holy")
    sign_in_as @user
  end

  test "keeps a verse, and keeping it again changes nothing" do
    2.times { post unit_keep_path(verse(3)), as: :json }
    assert_response :no_content
    assert_equal [ verse(3) ], @user.keeps.map(&:unit)
  end

  test "keeps even without a current focus" do
    @user.foci.current_one.archive!
    post unit_keep_path(verse(3)), as: :json
    assert_response :no_content
    assert_equal 1, @user.keeps.count
  end

  test "saves a remark" do
    @user.keeps.create!(unit: verse(3))
    patch unit_keep_path(verse(3)), params: { keep: { remark: "Come back to this" } }, as: :json
    assert_equal "Come back to this", @user.keeps.first.remark
  end

  test "a remark that's too long is refused and the old one kept" do
    @user.keeps.create!(unit: verse(3), remark: "first")
    patch unit_keep_path(verse(3)), params: { keep: { remark: "x" * 201 } }, as: :json
    assert_response :unprocessable_content
    assert_equal "first", @user.keeps.first.remark
  end

  test "a remark for something no longer kept is ignored" do
    patch unit_keep_path(verse(3)), params: { keep: { remark: "late" } }, as: :json
    assert_response :no_content
    assert_equal 0, Keep.where(user: @user).count
  end

  test "removes a verse" do
    @user.keeps.create!(unit: verse(3))
    delete unit_keep_path(verse(3)), as: :json
    assert_response :no_content
    assert_equal 0, Keep.where(user: @user).count
  end

  test "removing from the Kept page returns there, with Undo" do
    @user.keeps.create!(unit: verse(3), remark: "hm")
    delete unit_keep_path(verse(3))
    assert_redirected_to kept_path
    assert_equal 0, Keep.where(user: @user).count

    follow_redirect!
    assert_select ".focus-toast", /Removed Isaiah 40:3 from Kept/
    assert_select ".focus-toast form[action=?]", unit_keep_path(verse(3))
  end

  test "Undo puts a removed keep back as it was, remark and place in the list" do
    kept_at = 3.days.ago
    @user.keeps.create!(unit: verse(3), remark: "hm", created_at: kept_at)
    @user.keeps.create!(unit: verse(20), created_at: 1.day.ago)
    delete unit_keep_path(verse(3))
    follow_redirect!
    undo = css_select(".focus-toast form").first
    post undo["action"], params: css_select(".focus-toast form input[type=hidden]").to_h { [ it["name"], it["value"] ] }
    assert_redirected_to kept_path

    keep = @user.keeps.find_by(unit: verse(3))
    assert_equal "hm", keep.remark
    assert_in_delta kept_at, keep.created_at, 1.second
    follow_redirect!
    assert_equal [ "Isaiah 40:20", "Isaiah 40:3" ], css_select(".entry-ref").map(&:text)
    assert_select ".focus-toast", 0
  end

  test "Undo can't date a keep in the future" do
    post unit_keep_path(verse(3)), params: { kept_at: 1.year.from_now.iso8601 }
    assert_operator @user.keeps.first.created_at, :<=, Time.current
  end

  test "the Kept page removes without asking" do
    @user.keeps.create!(unit: verse(3))
    get kept_path
    assert_select "form[action=?] button.kept-act-remove:not([data-turbo-confirm])", unit_keep_path(verse(3)), "Remove"
    assert_select "form[data-turbo-confirm]", 0
  end

  test "can't touch another reader's keeps" do
    users(:two).keeps.create!(unit: verse(3), remark: "theirs")
    delete unit_keep_path(verse(3)), as: :json
    patch unit_keep_path(verse(3)), params: { keep: { remark: "mine now" } }, as: :json
    assert_equal "theirs", users(:two).keeps.first.remark
  end

  test "the Kept page lists passages newest first, with remarks" do
    @user.keeps.create!(unit: verse(3), remark: "first one", created_at: 2.days.ago)
    @user.keeps.create!(unit: verse(20))
    get kept_path
    assert_response :success
    assert_equal [ "Isaiah 40:20", "Isaiah 40:3" ], css_select(".entry-ref").map(&:text)
    assert_select ".entry-passage a.entry-ref[href=?]", reading_path("isaiah-kjv", 40, 3)
    assert_select ".entry-passage .entry-remark", "first one"
    assert_select ".entry-passage .entry-remark", 1, "no remark, nothing in its place"
    assert_select ".entry-passage a[href=?]", new_focus_path(unit_id: verse(3).id)
    assert_select ".kept-desc", /apart from any focus/
  end

  test "the Kept page is one stream: passages, ideas and remarks set aside, newest first by when they were kept" do
    travel_to Time.zone.local(2026, 10, 20, 12) do
      @user.keeps.create!(unit: verse(3), created_at: 40.days.ago)
      @user.keeps.create!(remark: "Holiness", created_at: 3.days.ago)
      @user.keeps.create!(unit: verse(20), created_at: 1.day.ago)
      @user.keeps.create!(remark: "What should I stop doing?\nHeard in a sermon")
      DetachedNote.create!(user: @user, kept: true, content: "<p>The kettle</p>", citation: "Journal ¶4", work_title: "Journal",
                           passage: "The kettle sang.", reason: "revised", noted_at: 2.days.ago, edited_at: 2.days.ago)
      get kept_path
    end
    entries = css_select(".entry").map { it.at_css(".entry-ref, .idea-line").text.strip }
    assert_equal [ "What should I stop doing?", "Isaiah 40:20", "Journal ¶4", "Holiness", "Isaiah 40:3" ], entries
    assert_equal [ "October 2026", "September 2026" ], css_select(".kept-month").map(&:text)
    assert_select ".entry-idea .idea-rest", "Heard in a sermon"
    assert_select ".entry-idea .idea-rest", 1, "an idea of one line has nothing under it"
    assert_select ".entry-set-aside .entry-ref", "Journal ¶4"
    assert_select ".entry-set-aside a.entry-ref", 0, "its passage is gone"
    assert_select ".entry-set-aside button[data-turbo-confirm]", "Discard"
  end

  test "the Kept page is empty with a hint" do
    get kept_path
    assert_select ".page-empty"
    assert_select ".kept-desc", 0, "the hint says it already"
  end

  test "the Kept page shows only the reader's own" do
    users(:two).keeps.create!(unit: verse(3), remark: "theirs")
    users(:two).keeps.create!(remark: "their idea")
    get kept_path
    assert_select ".entry", 0
  end

  test "the Kept page starts a focus without asking: the current one stays among the others" do
    @user.keeps.create!(unit: verse(3))
    get kept_path
    assert_select "a[href=?]:not([data-turbo-confirm])", new_focus_path(unit_id: verse(3).id)
  end

  test "the Kept page's query count doesn't grow with the number of keeps" do
    @user.keeps.create!(unit: verse(1))
    @user.keeps.create!(remark: "an idea")
    one = count_queries { get kept_path }
    (2..6).each { |n| @user.keeps.create!(unit: verse(n)); @user.keeps.create!(remark: "idea #{n}") }
    six = count_queries { get kept_path }
    assert_equal one, six
  end

  test "the reading page carries what's kept, and the verse grid marks it" do
    @user.keeps.create!(unit: verse(3), remark: "hm")
    get reading_path("isaiah-kjv", 40, 1)
    assert_select ".keep[data-keep-kept-value=?]", { verse(3).id.to_s => "hm" }.to_json
    assert_select ".cell.kept", "3"
    assert_select ".cell.kept", 1
  end

  test "history marks kept places" do
    [ 3, 20, 10 ].each { |n| Visit.record(@user, verse(n)) }
    @user.keeps.create!(unit: verse(3))
    get history_path
    assert_select ".hist-kept", 1
  end

  test "Kept has the rail, its own icon marked, and no back chip" do
    get kept_path
    assert_select ".rail a.rail-btn[href=?][aria-current=page]", kept_path
    assert_select ".rail a.rail-continue[href=?]", continue_path
    assert_select "a", text: /Back/, count: 0
  end

  test "starting a focus from a kept passage opens at it" do
    @user.keeps.create!(unit: verse(25), remark: "the heart of it")
    get new_focus_path(unit_id: verse(25).id)
    assert_select ".start-from", /Isaiah 40:25/
    assert_select ".start-from em", "the heart of it"

    post foci_path, params: { unit_id: verse(25).id, focus: { title: "Strength" } }
    focus = @user.foci.current_one
    assert_equal "Strength", focus.title
    assert_equal verse(25), focus.last_unit
  end

  test "can't start a focus from someone else's kept passage" do
    users(:two).keeps.create!(unit: verse(25))
    post foci_path, params: { unit_id: verse(25).id, focus: { title: "Strength" } }
    assert_nil @user.foci.current_one.last_unit
  end

  private

  # Counts cached queries too: the query cache hides a repeated lookup from the database, but not its cost.
  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
