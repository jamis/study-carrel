# The work or collection a request names by slug (params[:work] or params[:collection]), the user's own texts
# (params[:texts]), or nil for the whole library.
module LibraryPlace
  private

  def library_place
    if params[:work].present? then Work.visible_to(Current.user).find_by!(slug: params[:work])
    elsif params[:collection].present? then Collection.find_by!(slug: params[:collection])
    elsif params[:texts].present? then OwnTexts.new(Current.user)
    end
  end
end
