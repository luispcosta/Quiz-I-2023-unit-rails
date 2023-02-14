# Assume we are combining this with AppointmnetStep2
class AppointmentsAlerterStep2
  class << self
    def schedule_alerts
      upcoming_appts = Appointment.confirmed.with_alerts.upcoming.includes(:user)

      upcoming_appts.find_each do |appt|
        next if appt.user&.alert_settings&.empty?

        check_and_create_hour_before_alert!(appt)
        check_and_create_half_a_day_before_alert!(appt)
        check_and_create_day_before_alert!(appt)
      end
    end

    private

    def check_and_create_hour_before_alert!(appt)
      return unless appt.alerts.hour.blank?
      return unless appt&.user&.has_alert_active_at?(hours_before: 1) && appt.starts_in?(1.hour)

      appt.alerts.hour.create!
      send_alert(appt)
    end

    def check_and_create_half_a_day_before_alert!(appt)
      return unless appt.alerts.half_a_day.blank?
      return unless appt&.user&.has_alert_active_at?(hours_before: 12) && appt.starts_in?(12.hours)

      appt.alerts.half_a_day.create!
      send_alert(appt)
    end

    def check_and_create_day_before_alert!(appt)
      return unless appt.alerts.day.blank?
      return unless appt&.user&.has_alert_active_at?(hours_before: 24) && appt.starts_in?(24.hours)

      appt.alerts.day.create!
      send_alert(appt)
    end

    def send_alert(appt)
      msg = "You have an appointment with #{appt.stylist.scheduled_message_title}"
      msg = "#{msg} at #{appt.date_time_format('%H:%M')} on #{appt.date_time_format('%Y-%m-%d')}" if appt.date_time
      appt.each_user_device { |device_id| Notification.send_appointment_alerts(msg, appt.offer_id || 1, device_id) }
    end
  end
end
