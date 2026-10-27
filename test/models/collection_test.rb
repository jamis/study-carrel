require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "works are listed by position within a collection" do
    c = Collection.create!(slug: "ot", name: "Old Testament", position: 1)
    b = Work.create!(title: "Exodus", slug: "exodus", collection: c, position: 2)
    a = Work.create!(title: "Genesis", slug: "genesis", collection: c, position: 1)

    assert_equal [ a, b ], c.works.to_a
  end

  test "deleting a collection leaves its works" do
    c = Collection.create!(slug: "ot", name: "Old Testament")
    w = Work.create!(title: "Genesis", slug: "genesis", collection: c)
    c.destroy!
    assert_nil w.reload.collection
  end

  test "collections are ordered by position" do
    z = Collection.create!(slug: "z", name: "Z", position: 2)
    a = Collection.create!(slug: "a", name: "A", position: 1)
    assert_equal [ a, z ], Collection.ordered.to_a
  end

  test "collections nest, with children ordered by position" do
    bible = Collection.create!(slug: "bible", name: "Bible")
    nt = Collection.create!(slug: "nt", name: "New Testament", parent: bible, position: 2)
    ot = Collection.create!(slug: "ot", name: "Old Testament", parent: bible, position: 1)

    assert_equal [ ot, nt ], bible.children.to_a
    assert_equal [ bible ], Collection.top_level.to_a
    assert_equal [ bible ], nt.ancestors
  end

  test "descendants and their works are reachable from the top" do
    scripture = Collection.create!(slug: "scripture", name: "Scripture")
    bible = Collection.create!(slug: "bible", name: "Bible", parent: scripture)
    ot = Collection.create!(slug: "ot", name: "Old Testament", parent: bible)
    genesis = Work.create!(title: "Genesis", slug: "genesis", collection: ot)
    other = Work.create!(title: "Walden", slug: "walden")

    assert_equal [ scripture, bible, ot ].map(&:id).sort, scripture.self_and_descendant_ids.sort
    assert_equal [ genesis ], scripture.all_works.to_a
    assert_equal [ scripture, bible ], ot.ancestors
    assert_not_includes scripture.all_works, other
  end

  test "a collection can't be nested inside itself or its own descendant" do
    a = Collection.create!(slug: "a", name: "A")
    b = Collection.create!(slug: "b", name: "B", parent: a)

    assert_not a.update(parent: a)
    assert_not a.update(parent: b)
    assert a.update(parent: nil)
  end

  test "deleting a collection promotes its children to the top level" do
    a = Collection.create!(slug: "a", name: "A")
    b = Collection.create!(slug: "b", name: "B", parent: a)
    a.destroy!
    assert_nil b.reload.parent
  end

  test "work counts include nested collections, a single-work collection counting as one" do
    scripture = Collection.create!(slug: "scripture", name: "Scripture")
    bible = Collection.create!(slug: "bible", name: "Bible", parent: scripture, single_work: true)
    ot = Collection.create!(slug: "ot", name: "Old Testament", parent: bible)
    world = Collection.create!(slug: "world", name: "World", parent: scripture)
    Work.create!(title: "Genesis", slug: "genesis", collection: ot)
    Work.create!(title: "Exodus", slug: "exodus", collection: ot)
    Work.create!(title: "Dhammapada", slug: "dhammapada", collection: world)
    Work.create!(title: "Gita", slug: "gita", collection: world)
    Work.create!(title: "Psalms of Solomon", slug: "pss", collection: scripture)

    counts = Collection.work_counts
    assert_equal({ scripture.id => 4, bible.id => 2, ot.id => 2, world.id => 2 }, counts)
    assert_equal 4, scripture.work_count
  end

  test "a user's own collection gets a random slug suffix, and is visible only to them" do
    bundled = Collection.create!(slug: "ot", name: "Old Testament")
    mine = users(:one).collections.create!(name: "Pearl of Great Price")

    assert_match(/\Apearl-of-great-price-[a-z0-9]{4}\z/, mine.slug)
    assert_equal [ bundled, mine ], Collection.visible_to(users(:one)).order(:id).to_a
    assert_equal [ bundled ], Collection.visible_to(users(:two)).to_a
  end

  test "a user's own collection nests only under their own, and holds only their own texts" do
    bundled = Collection.create!(slug: "ot", name: "Old Testament")
    mine = users(:one).collections.create!(name: "Mine")
    theirs = users(:two).collections.create!(name: "Theirs")

    assert_not users(:one).collections.new(name: "Under bundled", parent: bundled).valid?
    assert_not users(:one).collections.new(name: "Under theirs", parent: theirs).valid?
    assert users(:one).collections.new(name: "Under mine", parent: mine).valid?
    assert_not Collection.new(slug: "b", name: "Bundled under mine", parent: mine).valid?

    diary = UserText.new(title: "Diary", source: "Words.").publish!(users(:one))
    assert diary.update(collection: mine)
    assert_not diary.update(collection: theirs)
    assert_not diary.update(collection: bundled)
    assert_not Work.new(title: "Genesis", slug: "genesis", collection: mine).valid?
  end

  test "removing a user's own collection deletes its texts and nested collections, setting aside their notes" do
    user = users(:one)
    focus = user.foci.start!(title: "What is light?")
    pearl = user.collections.create!(name: "Pearl")
    inner = user.collections.create!(name: "Inner", parent: pearl)
    moses = UserText.new(title: "Moses", source: "Let there be light.", collection_id: pearl.id).publish!(user)
    abraham = UserText.new(title: "Abraham", source: "The stars.", collection_id: inner.id).publish!(user)
    loose = UserText.new(title: "Diary", source: "Words.").publish!(user)
    focus.notes.create!(unit: moses.sections.sole.units.sole, content: "On light")
    shelf = user.shelves.create!(name: "Mine")
    shelf.replace!([ pearl ])

    assert_difference -> { user.detached_notes.count } => 1, -> { Note.count } => -1 do
      pearl.remove!
    end
    assert_not Collection.exists?(pearl.id)
    assert_not Collection.exists?(inner.id)
    assert_not Work.exists?(moses.id)
    assert_not Work.exists?(abraham.id)
    assert Work.exists?(loose.id)
    assert_empty shelf.items.reload
    assert_equal "Moses", user.detached_notes.sole.work_title
  end
end
