require "application_system_test_case"

class AutosaveTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "a note that couldn't save stops retrying once you move on, and comes back when you return" do
    visit reading_path("isaiah-kjv", 40, 25)
    failing_saves

    find("lexxy-editor [contenteditable]").send_keys "To whom then will ye liken me?"
    assert_text "Couldn't save; retrying…"

    click_on "Verse 26"
    assert_selector ".ref", text: "26"
    attempts = save_attempts
    sleep 6 # past the first retry delay
    assert_equal attempts, save_attempts, "a closed editor kept retrying"

    working_saves
    click_on "Verse 25"
    assert_text "Saved changes that hadn't saved before"
    assert_equal "To whom then will ye liken me?", @focus.notes.find_by!(unit: verse(25)).content.to_plain_text.strip
  end

  private

  # Swap in a fetch that fails note saves (as a dropped connection would) and counts them.
  def failing_saves
    execute_script <<~JS
      window.saveAttempts = 0
      window.failSaves = true
      const realFetch = window.fetch
      window.fetch = (url, options = {}) => {
        if (options.method === "PUT" && String(url).endsWith("/note")) {
          window.saveAttempts++
          if (window.failSaves) return Promise.reject(new TypeError("Failed to fetch"))
        }
        return realFetch(url, options)
      }
    JS
  end

  def working_saves = execute_script("window.failSaves = false")
  def save_attempts = evaluate_script("window.saveAttempts")
end
