module Importer

  def self.import_all
    import_schools
    import_education_subjects
    import_managers
    import_teachers
    import_courses
    import_students
    import_carriers
    import_internship_offers
  end

  def self.encrypt_string(string)
    return unless string.present?
    Rails.env.production? ? string : 'GEBLOCKT'
  end

  def self.encrypt_email(email)
    return unless email.present?
    first, last = email.split '@'
    first = Digest::MD5.hexdigest first
    [first, last].join '@'
  end

  def self.unquote(string)
    string.gsub(/&\w+;/, '&quot;' => '"', '&amp;' => '&')
  end

  def self.import_schools
    puts 'import schools'

    LegacyDatum.where(old_table: 'schulen').order(:old_id).all.each do |legacy_datum|
      data = legacy_datum.data
      carrier_id = data['carrier_id'].to_i
      common_options = data.slice('id', 'name', 'street', 'zip', 'city', 'phone', 'fax', 'email')
      if carrier_id > 0
        common_options[:carrier] = Organisation.find(carrier_id)
        Organisation::School.create!(common_options)
      else
        Organisation.create!(common_options)
      end

      ActiveRecord::Base.connection.reset_pk_sequence!(Organisation.table_name)
    end
  end

  def self.import_managers
    puts 'import managers'

    fs = Organisation.find 2

    LegacyDatum.where(old_table: 'mitarbeiter').all.each do |legacy_datum|
      data = legacy_datum.data

      manager            = Person.new
      manager.first_name = data['vorname']
      manager.last_name  = data['nachname']
      manager.email      = data['email']
      manager.build_as_manager organisation: fs
      manager.save!

      manager.create_login do |login|
        login.email = data['email']
        login.password = login.password_confirmation = (data['vorname'] + data['nachname']).downcase
        login.confirm!
      end

      ActiveRecord::Base.connection.reset_pk_sequence!(Person.table_name)
    end

  end

  def self.import_education_subjects
    puts 'import education_subjects'
    LegacyDatum.where(old_table: 'ausbildungsart').all.each do |legacy_datum|
      data = legacy_datum.data

      education_subject            = EducationSubject.new
      education_subject.id         = data['id']
      education_subject.school_id  = data['school_id']
      education_subject.name       = data['name']
      education_subject.short_name = data['shortname']

      education_subject.save!
    end

    ActiveRecord::Base.connection.reset_pk_sequence!(EducationSubject.table_name)

  end

  def self.import_teachers
    puts 'import teachers'

    # fs = Organisation.find 2
    LegacyDatum.where(old_table: 'lehrer').all.each do |legacy_datum|
      data = legacy_datum.data

      if data['nachname'].in? %w(Quaas Hinne)
        teacher = Person.find_by first_name: data['vorname'], last_name: data['nachname']
        teacher.build_as_teacher id: data['id'].to_i + 1000
        teacher.save!
      else
        teacher            = Person.new
        teacher.first_name = data['vorname']
        teacher.last_name  = data['nachname']
        teacher.gender     = data['geschlecht'].to_i == 1 ? 'f' : 'm'
        teacher.email      = encrypt_email(data['email'])
        teacher.build_as_teacher id: data['id'].to_i + 1000
        teacher.save!
      end

    end

    ActiveRecord::Base.connection.reset_pk_sequence!(Person.table_name)
    ActiveRecord::Base.connection.reset_pk_sequence!(Role.table_name)
  end

  def self.import_courses
    puts 'import courses'
    LegacyDatum.where(old_table: 'klassen').all.each do |legacy_datum|
      data = legacy_datum.data
      # lehrer = LegacyDatum.find_by(old_table: 'lehrer', old_id: data['lehrer_id'])
      # puts lehrer.data
      # teacher = Role::Teacher.
      #   joins(:person).
      #   where(people: {first_name: lehrer.data['vorname'], last_name: lehrer.data['nachname']}).
      #   last
      teacher = Role::Teacher.where(id: data['lehrer_id'].to_i + 1000).last
      # puts data, lehrer.data unless teacher
      course                      = Course.new
      course.id                   = data['id']
      course.education_subject_id = data['ausbildungsart_id']
      course.name                 = data['name']
      course.teacher              = teacher
      course.start_date           = data['start_date']
      course.end_date             = data['end_date']
      course.save!

      course.reload
      teacher.update organisation: course.education_subject.school
    end

    ActiveRecord::Base.connection.reset_pk_sequence!(Course.table_name)
  end

  def self.import_students
    puts 'import students'
    LegacyDatum.where(old_table: 'azubi').all.each do |legacy_datum|
      data = legacy_datum.data
      begin
        course = Course.where(id: data['klasse']).first
        unless course
          puts 'no course ', data['klasse'], data['vorname'] + data['nachname']
          next
        end

        person            = Person.new
        person.first_name = data['vorname']
        person.last_name  = data['nachname']
        person.gender     = data['geschlecht'].to_i == 1 ? 'f' : 'm'
        person.email      = encrypt_email(data['email'])
        street, number     = data['strasse'], data['hausnummer']
        street             += (" #{number}") if number.present?
        person.street     = encrypt_string street
        person.zip        = data['plz']
        person.city       = data['ort']
        person.phone      = encrypt_string data['telefon']
        person.build_as_student(
          organisation: course.education_subject.school,
          courses: [course]
        )
        person.save!

        # generate_course_membership student, data
        # course = Course.find(data['klasse'])
        # person.as_student.courses << course if course


      rescue StandardError => e
        msg = "Student #{data['id']} (#{data['vorname']} #{data['nachname']}): "
        msg += person.errors.full_messages.join(', ')
        puts msg
      end

      # bundesland: Sachsen-Anhalt
      # landkreis: LK Harz
      # pp: 191
      # anleiter_id: 68
    end

    ActiveRecord::Base.connection.reset_pk_sequence!(Person.table_name)
    ActiveRecord::Base.connection.reset_pk_sequence!(CourseMembership.table_name)
  end

  def self.import_carriers
    puts 'import carriers'
    LegacyDatum.where(old_table: 'traeger').all.each do |legacy_datum|
      data = legacy_datum.data
      carrier                = Organisation.new
      carrier.id             = data['id'].to_i + 1000
      carrier.name           = unquote data['name_1']
      carrier.email          = encrypt_string data['email']
      street, number         = data['strasse'], data['hausnummer']
      street                 += (" #{number}") if number.present?
      carrier.street         = encrypt_string street
      carrier.zip            = data['plz']
      carrier.city           = data['ort']
      carrier.phone          = encrypt_string data['telefon']
      carrier.fax            = encrypt_string data['telefax']
      carrier.contact_person = encrypt_string "#{data['vorname']} #{data['nachname']}"
      carrier.homepage       = data['homepage']
      carrier.comments       = encrypt_string data['kurzbeschreibung']
      carrier.save!
      # geschlecht: 1
    end


    ActiveRecord::Base.connection.reset_pk_sequence!(Organisation.table_name)
  end

  def self.import_internship_offers
    puts 'import internship offers'
    # {
    #   carrier_id_1 => {
    #     'Kita Blah' => [data1, data2],
    #     'Kita Blub' => [data2, data4],
    #   },
    #   carrier_id_2 => {
    #     'Kita Blah2' => [data21, data22],
    #     'Kita Blub2' => [data22, data24],
    #   },
    # }
    mapping = {}

    LegacyDatum.where(old_table: 'praktikumsplatz').all.each do |legacy_datum|
      data = legacy_datum.data
      carrier_id = data['traeger_id'].to_i
      year = data['jahr'].to_i
      next if carrier_id == 0 or year != 2015
      carrier_id += 1000
      mapping[carrier_id] ||= {}
      mapping[carrier_id][data['name']] ||= []
      mapping[carrier_id][data['name']] << data
    end

    mapping.each do |carrier_id, internship_offers|
      begin
        carrier = Organisation.find carrier_id
        internship_offers.each do |name, internship_positions|
          internship_offer             = carrier.internship_offers.build
          internship_offer.name        = unquote name
          internship_offer.email       = encrypt_string first_present(internship_positions, 'email')
          street                       =  first_present(internship_positions, 'strasse')
          number                       =  first_present(internship_positions, 'hausnummer')
          street                       += (" #{number}") if number.present?
          internship_offer.street      = encrypt_string street
          internship_offer.zip         = first_present(internship_positions, 'plz')
          internship_offer.city        = first_present(internship_positions, 'ort')
          internship_offer.phone       = encrypt_string first_present(internship_positions, 'telefon')
          internship_offer.fax         = encrypt_string first_present(internship_positions, 'telefax')
          internship_offer.homepage    = first_present(internship_positions, 'homepage')
          internship_offer.description = first_present(internship_positions, 'kurzbeschreibung')
          accommodation                = internship_offer.accommodation_options
          accommodation.possible       = first_present(internship_positions, 'unterkunft').to_i == 1
          accommodation.costs          = first_present(internship_positions, 'unterkunftkosten')
          application                  = internship_offer.application_options
          application.by_phone         = first_present(internship_positions, 'bewerbungtele')
          application.by_email         = first_present(internship_positions, 'bewerbungmail')
          application.by_mail          = first_present(internship_positions, 'bewerbungpost')
          application.documents        = first_present(internship_positions, 'bewerbungsunterlagen')
          internship_offer.save!

          internship_positions.group_by { |i| i['art'].to_i }.each do |education_subject_id, array|
            internship_offer.internship_positions.create!(
              education_subject_id: education_subject_id,
              number_of_positions: array.size
            )
          end

        end
      rescue ActiveRecord::RecordNotFound => e

      end
    end


    ActiveRecord::Base.connection.reset_pk_sequence!(InternshipOffer.table_name)
  end

  def self.first_present(array, attribute)
    array.map { |data| data[attribute] }.uniq.compact.first
  end

  def self.import_time_blocks
    puts 'import time blocks'

    TimeBlock.delete_all

    TimeBlock.create! [
        {start_time:  '8:00', end_time:  '9:30', position: 1, active: true}, # 08.00 bis 09.30 Uhr
        {start_time:  '9:45', end_time: '11:15', position: 2, active: true}, # 09.45 bis 11.15 Uhr
        {start_time: '11:30', end_time: '13:00', position: 3, active: true}, # 11.30 bis 13.00 Uhr
        {start_time: '13:30', end_time: '15:00', position: 4, active: true}, # 13.30 bis 15.00 Uhr
        {start_time: '15:15', end_time: '16:45', position: 5, active: true}, # 15.15 bis 16.45 Uhr
      ]

    ActiveRecord::Base.connection.reset_pk_sequence!(TimeBlock.table_name)
  end


end
