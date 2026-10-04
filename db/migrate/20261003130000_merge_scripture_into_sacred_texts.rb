# Folds Bible, Book of Mormon and the World Scripture works into one "Sacred Texts" collection and
# drops "LDS Scripture" and "World Scripture". Works are moved, never deleted, so notes survive.
class MergeScriptureIntoSacredTexts < ActiveRecord::Migration[8.0]
  class Collection < ActiveRecord::Base; end
  class Work < ActiveRecord::Base; end

  def up
    sacred = Collection.find_or_create_by!(slug: "sacred-texts") do |c|
      c.name = "Sacred Texts"
      c.position = 3
      c.description = "Scripture from several traditions, in public-domain translations. Older translations read differently from modern ones."
    end

    Collection.where(slug: "bible").update_all(parent_id: sacred.id, position: 1)
    Collection.where(slug: "book-of-mormon").update_all(parent_id: sacred.id, position: 2)
    Collection.where(slug: "poetry").update_all(position: 1)
    Collection.where(slug: "prose").update_all(position: 2)

    if (world = Collection.find_by(slug: "world-scripture"))
      Work.where(collection_id: world.id).update_all(collection_id: sacred.id)
      world.destroy
    end
    Collection.find_by(slug: "lds-scripture")&.destroy
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
