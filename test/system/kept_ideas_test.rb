require "application_system_test_case"

class KeptIdeasTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @user = users(:one)
    @user.foci.start!(title: "Holy")
    sign_in_as @user
    visit kept_path
  end

  test "n opens the slip; Shift+Enter is a new line and Enter keeps it at the head of the stream" do
    find("body").send_keys "n"
    field = find(".jot-form textarea")
    assert_equal field, page.active_element
    field.send_keys "What should I stop doing?", [ :shift, :enter ], "Heard in a sermon", :enter

    assert_selector ".entry-idea .idea-line", text: "What should I stop doing?"
    assert_selector ".entry-idea .idea-rest", text: "Heard in a sermon"
    assert_selector ".jot-open", visible: true
    assert_equal "What should I stop doing?\nHeard in a sermon", @user.keeps.ideas.sole.remark
  end

  test "Esc leaves the slip with nothing kept; a tap away keeps what was written" do
    find(".jot-open").click
    find(".jot-form textarea").send_keys "Never mind", :escape
    assert_selector ".jot-open", visible: true
    assert_equal find(".jot-open"), page.active_element
    assert_equal 0, @user.keeps.count

    find(".jot-open").click
    find(".jot-form textarea").send_keys "Holiness"
    find(".kept-title").click
    assert_selector ".entry-idea .idea-line", text: "Holiness"
    assert_equal "Holiness", @user.keeps.ideas.sole.remark
  end

  test "pressing an idea writes it again in place" do
    @user.keeps.create!(remark: "Holiness")
    visit kept_path
    find(".idea-text").click
    field = find(".entry-idea textarea")
    field.send_keys " in Isaiah", :enter
    assert_selector ".entry-idea .idea-line", text: "Holiness in Isaiah"
    assert_equal "Holiness in Isaiah", @user.keeps.ideas.sole.reload.remark

    find(".idea-text").click
    find(".entry-idea textarea").send_keys " and Amos", :escape
    assert_selector ".entry-idea .idea-line", text: "Holiness in Isaiah"
    assert_equal "Holiness in Isaiah", @user.keeps.ideas.sole.reload.remark
  end

  test "the characters left show near the end" do
    find(".jot-open").click
    find(".jot-form textarea").send_keys "x" * 150
    assert_no_selector ".jot-left", text: /left/
    find(".jot-form textarea").send_keys "x" * 30
    assert_selector ".jot-left", text: "20 left"
  end
end
