ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # One real book is enough for most tests; the full library is only loaded where it's the point.
    def load_isaiah
      TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
      TextLoader.load_file(Rails.root.join("db/texts/isaiah-kjv.txt"))
    end

    # Isaiah 40:n, the chapter most tests read.
    def verse(number)
      Unit.joins(section: :work).find_by!(works: { slug: "isaiah-kjv" }, sections: { number: 40 }, number: number)
    end
  end
end
