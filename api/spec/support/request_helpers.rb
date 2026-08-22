# frozen_string_literal: true

# Helpers shared by request specs: default tenant org + JWT auth headers.
module RequestSpecHelpers
  # Ensures the default Organization (id 0) used by tenant resolution exists.
  def ensure_default_org
    create(:organization, id: 0)
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def auth_token(role: "admin", scheme: "test-corp", user_id: 1)
    JsonWebToken.encode({ user_id:, role:, scheme: })
  end

  def auth_headers(role: "admin", scheme: "test-corp", user_id: 1)
    { "Authorization" => "Bearer #{auth_token(role:, scheme:, user_id:)}" }
  end
end

RSpec.configure do |config|
  config.include RequestSpecHelpers, type: :request

  config.before(:each, type: :request) do
    ensure_default_org
  end
end
