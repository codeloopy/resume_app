# frozen_string_literal: true

require "test_helper"

class ResumeEventTest < ActiveSupport::TestCase
  test "tracks view event" do
    resume = resumes(:one)
    assert_difference "ResumeEvent.count", 1 do
      ResumeEvent.track!(resume: resume, event_type: "view")
    end
    event = ResumeEvent.last
    assert_equal resume, event.resume
    assert_equal "view", event.event_type
  end

  test "tracks download event" do
    resume = resumes(:one)
    assert_difference "ResumeEvent.count", 1 do
      ResumeEvent.track!(resume: resume, event_type: "download")
    end
    event = ResumeEvent.last
    assert_equal "download", event.event_type
  end

  test "rejects invalid event type" do
    resume = resumes(:one)
    assert_raises(ActiveRecord::RecordInvalid) do
      ResumeEvent.track!(resume: resume, event_type: "invalid")
    end
  end
end
