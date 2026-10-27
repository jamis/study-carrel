# For deleting or revising a user's own texts: how many notes and kept remarks were set aside as detached notes while
# a block ran, and the words saying so.
module SetsAsideNotes
  private

  def set_aside_count
    before = Current.user.detached_notes.count
    yield
    Current.user.detached_notes.count - before
  end

  def set_aside_message(count)
    " #{count == 1 ? "One note was" : "#{count} notes were"} set aside with the passages they were written on." if count.positive?
  end
end
