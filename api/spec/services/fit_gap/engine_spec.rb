# frozen_string_literal: true

require "rails_helper"

RSpec.describe FitGap::Engine do
  let(:gemini_client) { double("GeminiClient", generate_content: { "culture_narrative" => "c", "overall_narrative" => "o" }) }

  let(:portfolio) do
    create(:portfolio).tap do |p|
      create(:portfolio_skill, portfolio: p, skill_label: "Ruby", ai_level: 3)
      create(:portfolio_skill, portfolio: p, skill_label: "Go", ai_level: 2)
    end
  end

  let(:vacancy) do
    create(:vacancy).tap do |v|
      create(:vacancy_skill, vacancy: v, skill_label: "Ruby", expected_level: 3)
      create(:vacancy_skill, vacancy: v, skill_label: "Go", expected_level: 4)
      create(:vacancy_skill, vacancy: v, skill_label: "Python", expected_level: 2)
    end
  end

  subject(:engine) { described_class.new(portfolio:, vacancy:, gemini_client:) }

  describe "#call" do
    let(:report) { engine.call }

    it "emits expected_level (not required_level) per comparison" do
      expect(report.skill_comparisons.first).to have_key("expected_level")
      expect(report.skill_comparisons.first).not_to have_key("required_level")
    end

    it "emits overridden flag, false by default for skills without an override" do
      ruby = report.skill_comparisons.find { |c| c["skill_label"] == "Ruby" }
      expect(ruby["overridden"]).to eq(false)
    end

    it "sets a 16-char source_fingerprint on the report" do
      expect(report.source_fingerprint).to be_a(String)
      expect(report.source_fingerprint.length).to eq(16)
    end
  end

  describe "overridden propagation" do
    it "marks the comparison overridden when an AssessorOverride exists" do
      skill = portfolio.portfolio_skills.find_by(skill_label: "Ruby")
      create(:assessor_override, portfolio_skill: skill, override_level: 5)

      report = described_class.new(portfolio:, vacancy:, gemini_client:).call
      ruby = report.skill_comparisons.find { |c| c["skill_label"] == "Ruby" }

      expect(ruby["overridden"]).to eq(true)
      expect(ruby["candidate_level"]).to eq(5)
    end
  end

  describe "#compute_fingerprint" do
    it "changes when an override is added (AC8 stale detection)" do
      f1 = described_class.new(portfolio:, vacancy:, gemini_client:).send(:compute_fingerprint)

      skill = portfolio.portfolio_skills.find_by(skill_label: "Ruby")
      create(:assessor_override, portfolio_skill: skill, override_level: 5, overridden_at: 1.second.from_now)

      f2 = described_class.new(portfolio:, vacancy:, gemini_client:).send(:compute_fingerprint)

      expect(f1).not_to eq(f2)
    end

    it "changes when a portfolio skill level changes" do
      f1 = described_class.new(portfolio:, vacancy:, gemini_client:).send(:compute_fingerprint)

      skill = portfolio.portfolio_skills.find_by(skill_label: "Ruby")
      skill.update!(ai_level: 5)

      f2 = described_class.new(portfolio:, vacancy:, gemini_client:).send(:compute_fingerprint)

      expect(f1).not_to eq(f2)
    end
  end
end
