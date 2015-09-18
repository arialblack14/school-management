class Carrier < ActiveRecord::Base

  has_many :institutions, inverse_of: :carrier
  has_many :mentors, inverse_of: :carrier

  rails_admin do
    navigation_label 'Praktikum'
  end
end