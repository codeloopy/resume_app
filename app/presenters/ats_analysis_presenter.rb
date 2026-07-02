# frozen_string_literal: true

# Filters ATS analysis output based on the user's subscription tier.
class AtsAnalysisPresenter
  FREE_SUGGESTION_LIMIT = 3

  def initialize(analysis, user:)
    @analysis = analysis
    @user = user
  end

  def score
    @analysis[:score]
  end

  def grade
    @analysis[:grade]
  end

  def suggestions
    items = @analysis[:suggestions] || []
    full_access? ? items : items.first(FREE_SUGGESTION_LIMIT)
  end

  def breakdown
    full_access? ? @analysis[:breakdown] : {}
  end

  def full_access?
    @user.deep_ats_analysis?
  end

  def locked?
    !full_access?
  end
end
