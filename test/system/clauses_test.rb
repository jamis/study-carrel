require "application_system_test_case"

class ClausesTest < ApplicationSystemTestCase
  setup do
    TextLoader.new(<<~TXT).load
      work: Self-Reliance
      unit: sentence
      group: paragraph

      section: 1
      label: Self-Reliance
      1.1 Trust thyself: every heart vibrates to that iron string.
      1.2 In the attempt his genius deserts him; no muse befriends; no invention, no hope.

      section: 2
      label: More
      1.1 Well, a foolish consistency is the hobgoblin of little minds, adored by little statesmen.
    TXT
    users(:one).foci.start!(title: "Deliberately")
    sign_in_as users(:one)
  end

  test "; reads a sentence a clause at a time, the arrows stepping through its clauses and on into the next" do
    visit reading_path("self-reliance", 1, 1)
    assert_no_selector ".now.clauses"
    find(".now [data-lectio-target='body']").click # clicking the text alone doesn't turn it on
    assert_no_selector ".now.clauses"

    find("body").send_keys ";"
    assert_selector ".clause.current", text: "Trust thyself:"
    assert_selector ".step-pips i", count: 2

    find("body").send_keys "j"
    assert_selector ".clause.current", text: "every heart vibrates to that iron string."
    assert_selector ".step-of", text: "1 of 2"

    find("body").send_keys "j"
    assert_selector ".step-of", text: "2 of 2"
    assert_selector ".clause.current", text: "In the attempt his genius deserts him;"
    assert_selector ".step-pips i", count: 4
    assert_selector ".clause", text: "no invention," # two words stand alone

    find(".clause", text: "no hope.").click
    assert_selector ".clause.current", text: "no hope."

    find("body").send_keys "k"
    assert_selector ".clause.current", text: "no invention,"
    find("body").send_keys "K"
    assert_selector ".step-of", text: "1 of 2"
    assert_selector ".clause.current", text: "Trust thyself:"

    find(".step-of").click # into the previous sentence lands on its last clause
    find(".cell[aria-label='Sentence 1:2']").click
    find("body").send_keys "k"
    assert_selector ".clause.current", text: "every heart"

    find(".step-clauses").click
    assert_no_selector ".now.clauses"
  end

  test "holding a key down steps once, not on through the clauses" do
    visit reading_path("self-reliance", 1, 2)
    find("body").send_keys ";"
    assert_selector ".clause.current", text: "In the attempt his genius deserts him;"

    execute_script(<<~JS)
      for (const repeat of [false, true, true, true])
        document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "j", repeat, bubbles: true }))
    JS
    assert_selector ".clause.current", text: "no muse befriends;"
  end

  test "reading by clause carries into the next chapter, and ends on leaving the reader" do
    visit reading_path("self-reliance", 1, 2)
    find("body").send_keys ";"
    find("body").send_keys "j", "j", "j", "j"
    assert_current_path reading_path("self-reliance", 2, 1)
    assert_selector ".clause.current", text: "Well, a foolish consistency" # a lone word joins the next clause

    find("body").send_keys "k"
    assert_current_path reading_path("self-reliance", 1, 2)
    assert_selector ".clause.current", text: "no hope."

    visit library_path
    visit reading_path("self-reliance", 1, 2)
    assert_text "In the attempt his genius deserts him; no muse befriends;"
    assert_no_selector ".now.clauses"
  end

  test "a verse breaks at the ends of its sentences too" do
    TextLoader.new(<<~TXT).load
      work: Jonah
      slug: jonah
      unit: verse

      section: 4
      1. But it displeased Jonah exceedingly, and he was very angry.
      2. And he prayed unto the LORD, and said, I pray thee, O LORD, was not this my saying, when I was yet in my country? Therefore I fled before unto Tarshish.
    TXT
    visit reading_path("jonah", 4, 2)
    find("body").send_keys ";"
    find("body").send_keys "j", "j", "j", "j", "j"
    assert_selector ".clause.current", text: "when I was yet in my country?"
    find("body").send_keys "j"
    assert_selector ".clause.current", text: "Therefore I fled before unto Tarshish."
  end

  test "the pips choose where to break, remembered in this browser" do
    visit reading_path("self-reliance", 1, 2)
    find("body").send_keys ";"
    assert_selector ".step-pips i", count: 4
    find(".step-pips").click
    within(".clause-breaks") { click_on "Break at commas" }
    assert_selector ".step-pips i", count: 3
    assert_selector ".clause", text: "no invention, no hope."

    visit reading_path("self-reliance", 1, 2) # still in the reader, so still by clause
    assert_selector ".step-pips i", count: 3
  ensure
    execute_script("localStorage.removeItem('study-clause-breaks')")
  end
end
