# frozen_string_literal: true

FactoryBot.define do
  factory :vacancy do
    tenant_id { 0 }
    created_by { 1 }
    role_title { "Engineer #{SecureRandom.hex(3)}" }
  end
end
