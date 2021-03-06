require 'support/helpers/session_helpers'
RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :feature
  config.include Features::PeopleHelpers, type: :feature
  config.include Features::CourseHelpers, type: :feature
  config.include Features::TimetableHelpers, type: :feature
  config.include Features::InternshipHelpers, type: :feature
  config.include Features::ClickableTableHelpers, type: :feature
end
