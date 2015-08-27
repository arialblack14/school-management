json.array!(@courses) do |course|
  json.extract! course, :id, :name, :education_subject, :teacher_id, :start_date, :end_date
  json.url course_url(course, format: :json)
end
