# The work or collection a request names by slug (params[:work] or params[:collection]), the user's own texts
# (params[:texts]), one of their shelves (params[:shelf]), or nil for the whole library.
module LibraryPlace
  # The place named by keys like a request's (work:, collection:, texts:, shelf:), raising RecordNotFound for one that
  # isn't there or isn't the user's to see.
  def self.find(keys, user)
    if keys[:work].present? then Work.visible_to(user).find_by!(slug: keys[:work])
    elsif keys[:collection].present? then Collection.find_by!(slug: keys[:collection])
    elsif keys[:texts].present? then OwnTexts.new(user)
    elsif keys[:shelf].present? then user.shelves.find_by!(slug: keys[:shelf])
    end
  end

  private

  def library_place = LibraryPlace.find(params, Current.user)
end
