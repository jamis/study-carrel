require "test_helper"

class IdeasControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @user = users(:one)
    @user.foci.start!(title: "Holy")
    sign_in_as @user
  end

  test "jots an idea, with no passage, and goes back to Kept" do
    post ideas_path, params: { keep: { remark: "  What am I doing that I should stop doing?\nHeard in a sermon " } }
    assert_redirected_to kept_path
    idea = @user.keeps.sole
    assert_nil idea.unit
    assert_equal "What am I doing that I should stop doing?\nHeard in a sermon", idea.remark

    follow_redirect!
    assert_select ".entry-idea .idea-line", "What am I doing that I should stop doing?"
    assert_select ".entry-idea .idea-rest", "Heard in a sermon"
  end

  test "an empty or too-long idea isn't kept" do
    post ideas_path, params: { keep: { remark: "  " } }
    post ideas_path, params: { keep: { remark: "x" * 201 } }
    assert_redirected_to kept_path
    assert_equal 0, @user.keeps.count
  end

  test "writes an idea again; emptied or too long, it stays as it was" do
    idea = @user.keeps.create!(remark: "Holiness")
    patch idea_path(idea), params: { keep: { remark: "Holiness in Isaiah" } }
    assert_redirected_to kept_path
    assert_equal "Holiness in Isaiah", idea.reload.remark

    patch idea_path(idea), params: { keep: { remark: "" } }
    patch idea_path(idea), params: { keep: { remark: "x" * 201 } }
    assert_equal "Holiness in Isaiah", idea.reload.remark
  end

  test "removing an idea goes back to Kept with Undo, which puts it back where it was" do
    kept_at = 3.days.ago
    idea = @user.keeps.create!(remark: "Holiness\nStart in Leviticus", created_at: kept_at)
    @user.keeps.create!(unit: verse(3), created_at: 1.day.ago)
    delete idea_path(idea)
    assert_redirected_to kept_path
    assert_not Keep.exists?(idea.id)

    follow_redirect!
    assert_select ".focus-toast", /Removed “Holiness” from Kept/
    undo = css_select(".focus-toast form").first
    post undo["action"], params: css_select(".focus-toast form input[type=hidden]").to_h { [ it["name"], it["value"] ] }
    assert_redirected_to kept_path

    back = @user.keeps.ideas.sole
    assert_equal "Holiness\nStart in Leviticus", back.remark
    assert_in_delta kept_at, back.created_at, 1.second
    follow_redirect!
    assert_equal [ "Isaiah 40:3", "Holiness" ], css_select(".entry-ref, .idea-line").map { it.text.strip }
    assert_select ".focus-toast", 0
  end

  test "an idea's actions: Start a focus, and Remove without asking" do
    idea = @user.keeps.create!(remark: "Holiness")
    get kept_path
    assert_select ".entry-idea a.kept-act[href=?]", new_focus_path(keep_id: idea.id), "Start a focus"
    assert_select ".entry-idea form[action=?]:not([data-turbo-confirm]) button.kept-act-remove", idea_path(idea), "Remove"
    assert_select ".entry-idea form.jot-form[action=?] textarea[maxlength='200']", idea_path(idea), "Holiness"
  end

  test "the Kept page offers the jot slip, with nothing kept too" do
    get kept_path
    assert_select ".jot-open", /Jot an idea/
    assert_select "form.jot-form[action=?][method=post] textarea[name='keep[remark]']", ideas_path
  end

  test "starting a focus from an idea fills in the form, and the idea goes once the focus is made" do
    idea = @user.keeps.create!(remark: "What should I stop doing?\nHeard in a sermon.\nTry Ecclesiastes.")
    get new_focus_path(keep_id: idea.id)
    assert_select "input[name='focus[title]'][value=?]", "What should I stop doing?"
    assert_select "textarea[name='focus[description]']", "Heard in a sermon.\nTry Ecclesiastes."
    assert_select "input[type=hidden][name=keep_id][value=?]", idea.id.to_s
    assert_select ".start-from", /From an idea you kept/

    post foci_path, params: { keep_id: idea.id, focus: { title: "What should I stop?", description: "From a sermon" } }
    assert_redirected_to continue_path
    focus = @user.foci.current_one
    assert_equal [ "What should I stop?", "From a sermon" ], [ focus.title, focus.description ]
    assert_nil focus.last_unit
    assert_not Keep.exists?(idea.id)
  end

  test "an idea stays if the focus isn't made" do
    idea = @user.keeps.create!(remark: "Holiness")
    post foci_path, params: { keep_id: idea.id, focus: { title: "" } }
    assert_response :unprocessable_entity
    assert Keep.exists?(idea.id)
  end

  test "if the idea can't be removed, the focus isn't made either" do
    idea = @user.keeps.create!(remark: "Holiness")
    # Rolled back with the test's transaction.
    Keep.connection.execute("CREATE TRIGGER keep_stays BEFORE DELETE ON keeps BEGIN SELECT RAISE(ABORT, 'stays'); END")
    assert_no_difference -> { @user.foci.count } do
      assert_raises(ActiveRecord::StatementInvalid) do
        post foci_path, params: { keep_id: idea.id, focus: { title: "Holiness" } }
      end
    end
    assert Keep.exists?(idea.id)
  end

  test "ideas aren't in the reader or history" do
    @user.keeps.create!(remark: "Holiness")
    get reading_path("isaiah-kjv", 40, 1)
    assert_select ".keep[data-keep-kept-value=?]", {}.to_json
    assert_select ".cell.kept", 0
    Visit.record(@user, verse(3))
    get history_path
    assert_select ".hist-kept", 0
  end

  test "another reader's ideas can't be changed, removed or started from" do
    theirs = users(:two).keeps.create!(remark: "Theirs")
    patch idea_path(theirs), params: { keep: { remark: "Mine now" } }
    assert_response :not_found
    delete idea_path(theirs)
    assert_response :not_found
    get new_focus_path(keep_id: theirs.id)
    assert_select "input[name='focus[title]'][value]", 0
    post foci_path, params: { keep_id: theirs.id, focus: { title: "Taken" } }
    assert_equal "Theirs", theirs.reload.remark
  end

  test "a kept passage can't be changed or removed as an idea" do
    keep = @user.keeps.create!(unit: verse(3), remark: "hm")
    patch idea_path(keep), params: { keep: { remark: "changed" } }
    assert_response :not_found
    delete idea_path(keep)
    assert_response :not_found
    assert_equal "hm", keep.reload.remark
  end
end
