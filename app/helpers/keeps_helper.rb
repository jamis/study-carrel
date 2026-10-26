module KeepsHelper
  # When an entry on the Kept page was kept: a remark set aside keeps that (noted_at), not when it was set aside.
  def kept_time(entry) = entry.is_a?(Keep) ? entry.created_at : entry.noted_at
end
