class AppointmentMessage
  attr_accessor :appointment

  def initialize(appointment)
    @appointment = appointment
  end

  def build(title)
    if appointment.date_time
      I18n.t(
        "#{title}_with_time",
        locale: 'ur',
        stylist: appointment.stylist.status_message_title,
        dd: appointment.date_time_format('%d-%m-%Y'),
        tt: appointment.date_time_format('%l:%M %p')
      )
    else
      I18n.t(
        title,
        locale: 'ur',
        stylist: appointment.stylist.status_message_title
      )
    end
  end
end
