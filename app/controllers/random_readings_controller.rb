# Drops the reader into a random unit (see RandomScope) and on into lectio mode.
class RandomReadingsController < ApplicationController
  include LibraryPlace

  def show
    unit = RandomScope.new(library_place).unit or raise ActiveRecord::RecordNotFound
    section = unit.section
    redirect_to reading_path(section.work.slug, section.number, unit.number)
  end
end
