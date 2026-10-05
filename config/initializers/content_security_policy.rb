# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.script_src      :self
    # Inline styles stay allowed: Lexxy writes style attributes, and the landing page and
    # Turbo's progress bar use <style> blocks. A style nonce would switch 'unsafe-inline' off.
    policy.style_src       :self, :unsafe_inline
    policy.img_src         :self, :data
    policy.font_src        :self, :data
    policy.connect_src     :self
    policy.object_src      :none
    policy.base_uri        :self
    policy.form_action     :self
    policy.frame_ancestors :none
  end

  # The theme script and the importmap are inline, so scripts get a nonce. A fresh one per
  # request: the session id isn't loaded yet when the layout renders, so it gave an empty
  # nonce. Turbo ignores nonces when comparing <head> elements, so navigation is unaffected.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
