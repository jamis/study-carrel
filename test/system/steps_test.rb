require "application_system_test_case"

class StepsTest < ApplicationSystemTestCase
  setup do
    TextLoader.new(<<~TXT).load
      work: Proverbs
      unit: sentence
      group: paragraph

      section: 1
      label: Wisdom
      1.1 Hear, my son.
      1.2 #{"Let the wise hear, and will increase learning; and a man of understanding shall attain unto wise counsels, " * 6}to understand.
      1.3 Fear is the beginning.
    TXT
    users(:one).foci.start!(title: "Wisdom")
    sign_in_as users(:one)
  end

  test "the arrows stay where they are whatever the passage's length" do
    visit reading_path("proverbs", 1, 1)
    of, ahead = place(".step-of"), place(".step[title='Sentence 1:2']")

    click_on "Sentence 1:2" # the long one
    assert_selector ".step-of", text: "2 of 3"
    assert_equal of, place(".step-of")
    assert_equal ahead, place(".step[title='Sentence 1:3']")

    click_on "Sentence 1:3" # the › gone at the end keeps its room, so nothing slides sideways
    assert_selector ".step-of", text: "3 of 3"
    assert_equal of, place(".step-of")
  end

  test "every passage starts in the same place, in the same size, whatever its length" do
    visit reading_path("proverbs", 1, 1)
    size = "getComputedStyle(document.querySelector('.now')).fontSize"
    start, short = place(".now-head"), evaluate_script(size)

    click_on "Sentence 1:2" # the long one
    assert_selector ".step-of", text: "2 of 3"
    assert_equal start, place(".now-head")
    assert_equal short, evaluate_script(size)
  end

  test "a long reference keeps to one line, and the margins' arrows stand level with the first line" do
    TextLoader.new(<<~TXT).load
      work: Talks
      unit: sentence
      group: paragraph

      section: 4
      label: Quick to Help, Slow to Judge: The Savior Helps (and Does Not Judge) the Woman at the Well
      1.1 What did Christ focus on instead?
      1.2 He saw her need.
    TXT
    visit reading_path("proverbs", 1, 1)
    start = place(".now-head")
    visit reading_path("talks", 4, 1)
    assert_selector ".now-head .ref-work", text: /talks/i # the work title stays; the section name ellipsizes
    assert evaluate_script("(s => s.scrollWidth > s.clientWidth)(document.querySelector('.now-head .ref-section'))")
    assert_equal start, place(".now-head")

    line, arrow = evaluate_script(<<~JS)
      [document.querySelector("[data-lectio-target=body]").getClientRects()[0], document.querySelector(".side-next span").getBoundingClientRect()]
        .map((r) => [r.top, r.bottom])
    JS
    assert_in_delta (line.sum / 2), (arrow.sum / 2), 3
  end

  test "the margins either side of the passage step, gone at either end" do
    visit reading_path("proverbs", 1, 1)
    assert_no_selector ".side-prev", visible: true

    find(".side-next").click
    assert_selector ".step-of", text: "2 of 3"
    find(".side-next").click
    assert_selector ".step-of", text: "3 of 3"
    assert_no_selector ".side-next", visible: true

    find(".side-prev").click
    assert_selector ".step-of", text: "2 of 3"
  end

  test "on a phone, the steps stand on the note sheet's handle and the margins don't step" do
    page.current_window.resize_to(400, 800)
    visit reading_path("proverbs", 1, 2)
    assert_no_selector ".side", visible: true
    steps, handle = evaluate_script(<<~JS)
      [document.querySelector(".steps"), document.querySelector(".panel-handle")].map((el) => el.getBoundingClientRect().top)
    JS
    assert_in_delta handle, steps + evaluate_script("document.querySelector('.steps').offsetHeight"), 1
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  test "on a phone, a swipe anywhere below the focus steps, but not one on the focus" do
    page.current_window.resize_to(400, 800)
    visit reading_path("proverbs", 1, 1)
    focus, passage = evaluate_script(<<~JS)
      [".focus", ".now"].map((s) => document.querySelector(s).getBoundingClientRect()).map((r) => [r.top + r.height / 2, r.bottom])
    JS

    swipe(at: focus[0])
    assert_selector ".step-of", text: "1 of 3"

    swipe(at: passage[1] + 150) # the empty room under a short passage
    assert_selector ".step-of", text: "2 of 3"
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  private
    # A leftward swipe across the middle of the window, at that height.
    def swipe(at:)
      execute_script(<<~JS, at)
        const y = arguments[0], x = innerWidth / 2, target = document.elementFromPoint(x, y)
        const touch = (x) => new Touch({ identifier: 1, target, clientX: x, clientY: y })
        target.dispatchEvent(new TouchEvent("touchstart", { bubbles: true, touches: [touch(x + 100)] }))
        target.dispatchEvent(new TouchEvent("touchend", { bubbles: true, changedTouches: [touch(x - 100)] }))
      JS
    end

    # Where something is in the window, as [left, top].
    def place(selector)
      evaluate_script("(r => [Math.round(r.left), Math.round(r.top)])(document.querySelector(#{selector.to_json}).getBoundingClientRect())")
    end
end
