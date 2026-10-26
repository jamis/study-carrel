require "test_helper"

class ParameterFilterTest < ActiveSupport::TestCase
  setup do
    @filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  end

  test "what readers write is kept out of the logs" do
    params = {
      "user_text" => { "source" => "a private text", "title" => "Mine", "author" => "Me", "author_short" => "M" },
      "label" => { "name" => "grace" },
      "q" => "holy",
      "note" => { "content" => "my note" }
    }
    filtered = @filter.filter(params)

    assert_equal "[FILTERED]", filtered["user_text"]["source"]
    assert_equal "[FILTERED]", filtered["user_text"]["title"]
    assert_equal "[FILTERED]", filtered["user_text"]["author"]
    assert_equal "[FILTERED]", filtered["user_text"]["author_short"]
    assert_equal "[FILTERED]", filtered["label"]["name"]
    assert_equal "[FILTERED]", filtered["q"]
    assert_equal "[FILTERED]", filtered["note"]["content"]
  end

  test "keys that merely contain a q are still logged" do
    filtered = @filter.filter("request_id" => "abc", "unit_id" => "12", "sequence" => "3")

    assert_equal({ "request_id" => "abc", "unit_id" => "12", "sequence" => "3" }, filtered)
  end
end
