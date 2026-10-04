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
end
