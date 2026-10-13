require "test_helper"

class ShelfTest < ActiveSupport::TestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. In the beginning.\n").load
    TextLoader.new("work: Matthew\nedition: KJV\ncollection: new-testament\nposition: 1\n\nsection: 1\n1. The book of the generation.\n").load
    TextLoader.new("work: Walden\nunit: paragraph\ncollection: prose\nposition: 1\n\nsection: 1\nlabel: Economy\n1. I went to the woods.\n").load
    @user = users(:one)
    @shelf = @user.shelves.create!(name: "  Scripture   and more ")
    @genesis, @walden = Work.find_by!(slug: "genesis-kjv"), Work.find_by!(slug: "walden")
    @bible, @ot = Collection.find_by!(slug: "bible"), Collection.find_by!(slug: "old-testament")
  end

  test "a shelf gets a squished name and a slug with a random suffix" do
    assert_equal "Scripture and more", @shelf.name
    assert_match(/\Ascripture-and-more-[a-z0-9]{4}\z/, @shelf.slug)
    assert_not @user.shelves.new(name: " ").valid?
  end

  test "something under a collection on the shelf is on it through that collection" do
    @shelf.put!(@bible)
    assert @shelf.on?(@bible)
    assert_not @shelf.on?(@genesis)
    assert_equal @bible, @shelf.via(@genesis)
    assert_equal @bible, @shelf.via(@ot)
    assert @shelf.holds?(@genesis)
    assert_not @shelf.holds?(@walden)

    assert_no_difference -> { @shelf.items.count } do
      @shelf.put!(@genesis)
    end
  end

  test "putting a collection on takes in what's already there from under it" do
    @shelf.put!(@genesis)
    @shelf.put!(@walden)
    assert_equal [ @genesis ], @shelf.under(@bible)

    @shelf.put!(@bible)
    assert_equal [ @bible, @walden ], @shelf.members
  end

  test "replacing leaves out what a collection among them brings" do
    @shelf.replace!([ @genesis, @ot, @walden, nil, @walden ])
    assert_equal [ @ot, @walden ], @shelf.members
    @shelf.replace!([])
    assert_empty @shelf.members
  end

  test "its works are those on it and under its collections, and only ones the owner can see" do
    @shelf.replace!([ @bible, @walden ])
    assert_equal [ @genesis, Work.find_by!(slug: "matthew-kjv"), @walden ].map(&:id).sort, @shelf.work_ids.sort

    someone_elses = UserText.new(title: "Diary", source: "Private words.").publish!(users(:two))
    ShelfItem.create!(shelf: @shelf, work: someone_elses)
    assert_not_includes @shelf.reload.work_ids, someone_elses.id
    assert_not_includes @shelf.members, someone_elses
    assert_nil Shelf.thing_for(Shelf.key_for(someone_elses), @user)
  end

  test "a deleted text comes off every shelf" do
    diary = UserText.new(title: "Diary", source: "Words here.").publish!(@user)
    @shelf.put!(diary)
    assert_difference -> { ShelfItem.count }, -1 do
      diary.remove!
    end
  end

  test "deleting a shelf leaves the library alone" do
    @shelf.put!(@bible)
    assert_no_difference -> { Work.count + Collection.count } do
      @shelf.destroy!
    end
    assert_equal 0, ShelfItem.count
  end
end
