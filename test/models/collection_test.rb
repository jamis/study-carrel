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
end
