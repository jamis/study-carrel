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
end
