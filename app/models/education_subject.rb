class EducationSubject < ActiveRecord::Base

  validates :name, presence: true

  rails_admin do
    navigation_label 'Stammdaten'

    list do
      field :name
      field :short_name
    end
  end
end
