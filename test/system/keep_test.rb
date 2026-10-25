require "application_system_test_case"

class KeepTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
    visit reading_path("isaiah-kjv", 40, 8)
    @unit = Unit.find(find(".keep")["data-keep-unit-id-value"])
  end

  test "a remark saved with Enter comes back in the toast and on the ribbon" do
    find(".keep-btn").click
    within(".keep-toast") { click_on "Add a remark" }
    find("#keep-remark").send_keys "The word stands", :enter
    assert_selector ".keep-pop", visible: :hidden
    assert_selector ".keep-toast .keep-toast-remark", text: "“The word stands”"
    assert_selector ".keep-btn[title='Kept: “The word stands” (b)']"
    assert_saved_remark "The word stands"
  end

  test "Esc leaves the remark as it was; Save and a tap elsewhere save it" do
    users(:one).keeps.create!(unit: @unit, remark: "Before")
    visit reading_path("isaiah-kjv", 40, 8)

    find(".keep-btn").click
    find("#keep-remark").fill_in with: "Changed my mind"
    find("#keep-remark").send_keys :escape
    assert_selector ".keep-pop", visible: :hidden
    assert_selector ".keep-toast", visible: :hidden
    find(".keep-btn").click
    assert_equal "Before", find("#keep-remark").value

    find("#keep-remark").fill_in with: "After"
    click_on "Save"
    assert_selector ".keep-toast .keep-toast-remark", text: "“After”"
    assert_saved_remark "After"

    find(".keep-btn").click
    find("#keep-remark").fill_in with: "Elsewhere"
    find(".focus").click
    assert_selector ".keep-pop", visible: :hidden
    assert_selector ".keep-toast .keep-toast-remark", text: "“Elsewhere”"
    assert_saved_remark "Elsewhere"
  end

  private

  # The toast shows a remark before the server has it; give the request a moment to land.
  def assert_saved_remark(remark)
    deadline = Time.now + Capybara.default_max_wait_time
    sleep 0.05 until users(:one).keeps.find_by(unit: @unit)&.remark == remark || Time.now > deadline
    assert_equal remark, users(:one).keeps.find_by(unit: @unit)&.remark
  end
end
