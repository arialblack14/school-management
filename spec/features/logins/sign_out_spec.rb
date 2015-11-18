# Feature: Sign out
#   As a user
#   I want to sign out
#   So I can protect my account from unauthorized access
feature 'Sign out', :devise do

  # Scenario: User signs out successfully
  #   Given I am signed in
  #   When I sign out
  #   Then I see a signed out message
  scenario 'user signs out successfully' do
    login = FactoryGirl.create(:login)
    signin(login.email, login.password)
    expect(page).to have_content I18n.t 'devise.sessions.signed_in'
    click_link 'Abmelden'
    expect(page).to have_content I18n.t 'devise.sessions.signed_out'
  end

end


