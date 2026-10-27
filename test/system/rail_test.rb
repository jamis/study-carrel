require "application_system_test_case"

class RailTest < ApplicationSystemTestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. Let there be light.\n2. And there was light.\n").load
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "the labels open from an icon, not the rail's blank stretch, and stay while the pointer is on the rail" do
    visit library_path
    find(".rail").hover # its middle, between Kept and the foot
    assert_no_selector ".rail.labels"
    assert_no_selector ".rail-label", text: "Your focuses"

    find(".rail-btn[aria-label='Your focuses']").hover
    assert_selector ".rail.labels .rail-label", text: "Your focuses"
    find(".rail").hover
    assert_selector ".rail.labels"

    find("main, .page", match: :first).hover
    assert_no_selector ".rail.labels"
  end

  test "Random opens the places to pick from, the default first" do
    visit work_path("genesis-kjv")
    find(".rail-random .rail-btn").click
    within("#rail-random") do
      assert_text(/pick randomly from/i)
      assert_selector ".menu-item:first-of-type.menu-default", text: "Genesis"
      click_on "Genesis"
    end
    assert_selector ".lectio"
    assert_current_path %r{/read/genesis-kjv/}
  end

  test "the account at the foot of the rail holds light/dark and sign out" do
    visit library_path
    find(".rail-foot .rail-btn").click
    dark = evaluate_script("document.documentElement.dataset.theme")
    within("#rail-me") { click_on "Light / dark" } # it stays open, to toggle back
    assert_not_equal dark, evaluate_script("document.documentElement.dataset.theme")
    within("#rail-me") { click_on "Sign out" }
    assert_current_path new_session_path
  end
end
