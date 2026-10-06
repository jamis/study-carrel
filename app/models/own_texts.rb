# The place holding a user's own texts, so search and Random can be scoped to it as they are to a work, a collection or
# the whole library (?texts=yours, /texts/random).
class OwnTexts
  attr_reader :user

  def initialize(user) = @user = user

  def name = "Your Texts"

  def ==(other) = other.is_a?(OwnTexts) && other.user == user
  alias eql? ==
  def hash = [ self.class, user ].hash
end
