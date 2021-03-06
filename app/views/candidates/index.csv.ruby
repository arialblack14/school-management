require 'csv'

response.headers['Content-Disposition'] = %Q(attachment; filename="#{@filename}.csv")

CSV.generate(encoding: 'UTF-8', col_sep: ';', force_quotes: true) do |csv|
  csv << %w(Status Eingangsdatum Jahr
            Anrede Vorname Nachname Geburtsdatum Geburtsort
            Straße PLZ Ort
            E-Mail Telefon Mobil
            Schulausbildung bestät. Berufsausb bestät. sonstiges Praktika bestät. Führungszeugnis
            KLT Eingeladen Rueckmeldung ErgebnisKLT
            AusbVertr_gesendet zurück PraktVertr_gesendet zurück)
  @candidates.each do |candidate|
    interview      = candidate.interview
    address        = candidate.address
    contact        = candidate.contact
    prof_grad      = candidate.profession_graduate
    prof_proved    = prof_grad.proved ? 'ja' : 'nein'
    prof_proved    = '-' if prof_grad.graduate.blank?
    intern_proved  = candidate.internships_proved ? 'ja' : 'nein'
    intern_proved  = '-' if candidate.internships.blank?

    candidate.education_contract_sent

    csv << [
      human_status_name(candidate.status),
      (candidate.date ? l(candidate.date) : ''),
      candidate.year,

      { 'f' => 'Frau', 'm' => 'Herr' }[candidate.gender],
      candidate.first_name,
      candidate.last_name,
      ldate(candidate.date_of_birth),
      candidate.place_of_birth,

      address.street,
      address.zip,
      address.city,

      contact.email,
      contact.phone,
      contact.mobile,

      candidate.school_graduate.graduate,
      (candidate.school_graduate.proved ? 'ja' : 'nein'),
      prof_grad.graduate,
      prof_proved,
      prof_grad.comments,
      candidate.internships.to_s.gsub(/\n/, ' ').gsub(/\r/, ' '),
      intern_proved,
      (candidate.police_certificate ? 'ja' : 'nein'),

      (interview.date.present? ? l(interview.date) : ''),
      (interview.invited ? 'ja' : 'nein'),
      human_answer_name(interview.answer),
      human_result_name(interview.result),

      (candidate.education_contract_sent      ? l(candidate.education_contract_sent)      : ''),
      (candidate.education_contract_received  ? l(candidate.education_contract_received)  : ''),
      (candidate.internship_contract_sent     ? l(candidate.internship_contract_sent)     : ''),
      (candidate.internship_contract_received ? l(candidate.internship_contract_received) : ''),
    ]
  end
end
