# frozen_string_literal: true

require "test_helper"

class AtsAnalysisPresenterTest < ActiveSupport::TestCase
  FULL_ANALYSIS = {
    score: 72,
    grade: "B",
    suggestions: %w[one two three four five],
    breakdown: { contact_info: { score: 10, max: 15, label: "Contact" } }
  }.freeze

  test "free user sees limited suggestions and no breakdown" do
    user = User.new(subscription_tier: "free")
    presenter = AtsAnalysisPresenter.new(FULL_ANALYSIS, user: user)

    assert_equal 72, presenter.score
    assert_equal 3, presenter.suggestions.size
    assert_empty presenter.breakdown
    assert presenter.locked?
  end

  test "handles nil user gracefully" do
    presenter = AtsAnalysisPresenter.new(FULL_ANALYSIS, user: nil)

    assert_equal 3, presenter.suggestions.size
    assert presenter.locked?
  end

  test "growth user sees full analysis" do
    user = User.new(subscription_tier: "growth")
    presenter = AtsAnalysisPresenter.new(FULL_ANALYSIS, user: user)

    assert_equal 5, presenter.suggestions.size
    assert presenter.breakdown.present?
    refute presenter.locked?
  end
end
