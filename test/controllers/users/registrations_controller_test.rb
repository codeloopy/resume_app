require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "guest user can access upgrade form" do
    user = User.create_guest
    sign_in(user)

    get upgrade_guest_user_form_path
    assert_response :success
    assert_select "h1", "Complete Your Account"
  end

  test "guest user can upgrade to regular user" do
    user = User.create_guest
    sign_in(user)

    assert user.guest?

    put upgrade_guest_user_path, params: {
      user: {
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "John",
        last_name: "Doe",
        phone: "+1234567890",
        location: "New York, NY"
      }
    }

    user.reload
    assert_not user.guest?
    assert_equal "test@example.com", user.email
    assert_equal "John", user.first_name
    assert_equal "Doe", user.last_name
  end
end
