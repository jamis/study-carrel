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

  test "a remark for something no longer kept is ignored" do
    patch unit_keep_path(verse(3)), params: { keep: { remark: "late" } }, as: :json
    assert_response :no_content
    assert_equal 0, Keep.where(user: @user).count
  end

  test "releases a verse" do
    @user.keeps.create!(unit: verse(3))
    delete unit_keep_path(verse(3)), as: :json
    assert_response :no_content
    assert_equal 0, Keep.where(user: @user).count
  end

  test "releasing from the Kept page returns there" do
    @user.keeps.create!(unit: verse(3))
    delete unit_keep_path(verse(3))
    assert_redirected_to kept_path
    assert_equal 0, Keep.where(user: @user).count
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
    assert_select ".fv-ref", 2
    assert_select ".fv-ref:first-of-type", /Isaiah 40:20/
    assert_select ".fv-note", "first one"
    assert_select "a[href=?]", new_focus_path(unit_id: verse(3).id)
  end

  test "the Kept page can list in reading order" do
    @user.keeps.create!(unit: verse(20), created_at: 2.days.ago)
    @user.keeps.create!(unit: verse(3))
    get kept_path(order: "reading")
    assert_equal [ "Isaiah 40:3", "Isaiah 40:20" ], css_select(".fv-ref").map(&:text)
  end

  test "the Kept page is empty with a hint" do
    get kept_path
    assert_select ".page-empty"
  end

  test "the Kept page shows only the reader's own" do
    users(:two).keeps.create!(unit: verse(3), remark: "theirs")
    get kept_path
    assert_select ".fv-item", 0
  end

  test "the reading page carries what's kept, and the strip marks it" do
    @user.keeps.create!(unit: verse(3), remark: "hm")
    get reading_path("isaiah-kjv", 40, 1)
    assert_select ".keep[data-keep-kept-value=?]", { verse(3).id.to_s => "hm" }.to_json
    assert_select ".tick.kept", "3"
    assert_select ".tick.kept", 1
  end

  test "history marks kept places" do
    [ 3, 20, 10 ].each { |n| Visit.record(@user, verse(n)) }
    @user.keeps.create!(unit: verse(3))
    get history_path
    assert_select ".hist-kept", 1
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
end
