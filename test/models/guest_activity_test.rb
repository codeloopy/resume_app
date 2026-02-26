# frozen_string_literal: true

require "test_helper"

class GuestActivityTest < ActiveSupport::TestCase
  test "creates activity with valid event type" do
    activity = GuestActivity.track!(event_type: "signup")
    assert activity.persisted?
    assert_equal "signup", activity.event_type
  end

  test "tracks with guest user and session" do
    user = User.create!(
      email: "guest_test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "Guest",
      guest: true
    )
    activity = GuestActivity.track!(
      event_type: "wizard_completed",
      guest_user: user,
      session_id: "abc123",
      metadata: { step: "completed" }
    )
    assert activity.persisted?
    assert_equal user.id, activity.guest_user_id
    assert_equal "abc123", activity.session_id
    assert_equal({ "step" => "completed" }, activity.metadata)
  end

  test "stats_for_period returns correct counts" do
    GuestActivity.track!(event_type: "signup")
    GuestActivity.track!(event_type: "signup")
    GuestActivity.track!(event_type: "converted")

    stats = GuestActivity.stats_for_period(1.hour.ago)
    assert_equal 2, stats[:signups]
    assert_equal 1, stats[:conversions]
  end

  test "conversion_rate returns 0 when no signups" do
    assert_equal 0.0, GuestActivity.conversion_rate(1.day.ago)
  end

  test "conversion_rate calculates correctly" do
    3.times { GuestActivity.track!(event_type: "signup") }
    1.times { GuestActivity.track!(event_type: "converted") }
    assert_equal 33.3, GuestActivity.conversion_rate(1.hour.ago)
  end

  test "validates event_type inclusion" do
    activity = GuestActivity.new(event_type: "invalid")
    assert_not activity.valid?
    assert_includes activity.errors[:event_type], "is not included in the list"
  end
end
