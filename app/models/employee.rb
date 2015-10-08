class Employee < Person

  has_paper_trail

  rails_admin do

    navigation_label I18n.t(:basic_data)

    list do
      field :first_name, :self_link
      field :last_name, :self_link
      field(:email, :email)
      field :city
    end

    show do
      field :first_name
      field :last_name
      field(:email, :email)
      field(:created_at) { date_format :short }
      field(:updated_at) { date_format :short }
    end
  end
end