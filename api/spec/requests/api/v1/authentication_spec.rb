# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  describe "POST /api/v1/auth/login" do
    let!(:admin) { create(:user, email: "admin@example.com", password: "secret123", role: "admin") }
    let!(:regular) { create(:user, email: "user@example.com", password: "secret123", role: "user") }

    it "logs in an admin and returns a token (200)" do
      post "/api/v1/auth/login", params: { email: "admin@example.com", password: "secret123" }.to_json, headers: headers
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body.dig("user", "role")).to eq("admin")
    end

    # P1-4 FIX: a self-serve `user`-role account must be able to log in.
    it "logs in a user-role account and returns a token (200)" do
      post "/api/v1/auth/login", params: { email: "user@example.com", password: "secret123" }.to_json, headers: headers
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body.dig("user", "role")).to eq("user")
    end

    it "rejects a wrong password with 401" do
      post "/api/v1/auth/login", params: { email: "admin@example.com", password: "wrong" }.to_json, headers: headers
      expect(response.status).to eq(401)
    end

    it "rejects an unknown email with 401" do
      post "/api/v1/auth/login", params: { email: "nobody@example.com", password: "secret123" }.to_json, headers: headers
      expect(response.status).to eq(401)
    end
  end

  describe "POST /api/v1/auth/signup" do
    it "creates a user and returns a token (201)" do
      post "/api/v1/auth/signup",
           params: { email: "New@Example.com", password: "password123", role: "user" }.to_json,
           headers: headers
      expect(response.status).to eq(201)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body.dig("user", "email")).to eq("new@example.com")
      expect(body.dig("user", "role")).to eq("user")
    end

    it "defaults role to user when omitted" do
      post "/api/v1/auth/signup",
           params: { email: "default@example.com", password: "password123" }.to_json,
           headers: headers
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body).dig("user", "role")).to eq("user")
    end

    it "returns 422 for an invalid email" do
      post "/api/v1/auth/signup",
           params: { email: "not-an-email", password: "password123" }.to_json,
           headers: headers
      expect(response.status).to eq(422)
    end

    it "returns 422 for a missing password" do
      post "/api/v1/auth/signup",
           params: { email: "nopass@example.com" }.to_json,
           headers: headers
      expect(response.status).to eq(422)
    end
  end
end
