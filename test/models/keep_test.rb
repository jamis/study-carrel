require "test_helper"

class KeepTest < ActiveSupport::TestCase
  setup do
    load_isaiah
    @user = users(:one)
  end

  test "a remark is trimmed, and a blank one is none" do
    assert_equal "why", @user.keeps.create!(unit: verse(3), remark: "  why ").remark
    assert_nil @user.keeps.create!(unit: verse(4), remark: "   ").remark
  end

  test "a remark is short" do
    assert_not @user.keeps.build(unit: verse(3), remark: "x" * 201).valid?
  end

  test "one keep per user per unit" do
    @user.keeps.create!(unit: verse(3))
    assert_raises(ActiveRecord::RecordNotUnique) { @user.keeps.create!(unit: verse(3)).dup.save!(validate: false) }
  end

  test "an idea is a keep with no passage, and must have words" do
    idea = @user.keeps.create!(remark: "Holiness")
    assert idea.idea?
    assert_not @user.keeps.build(remark: "  ").valid?
    assert_not @user.keeps.build(remark: "x" * 201).valid?
    assert_equal [ idea ], @user.keeps.ideas
    assert_empty @user.keeps.passages
  end

  test "any number of ideas, though one keep per passage" do
    3.times { @user.keeps.create!(remark: "same thought") }
    assert_equal 3, @user.keeps.ideas.count
  end

  test "an idea's first line is its question or topic, and the rest where to begin" do
    idea = @user.keeps.build(remark: "What should I stop doing?\nHeard in a sermon.\nTry Ecclesiastes.")
    assert_equal "What should I stop doing?", idea.idea_title
    assert_equal "Heard in a sermon.\nTry Ecclesiastes.", idea.idea_rest
    assert_nil @user.keeps.build(remark: "Holiness").idea_rest
  end

  test "revising or deleting a text leaves ideas alone" do
    idea = @user.keeps.create!(remark: "Holiness")
    DetachedNote.set_aside!(Unit.where(id: verse(3).id), reason: "deleted")
    assert Keep.exists?(idea.id)
  end
end
