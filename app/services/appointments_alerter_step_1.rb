# Assume we are combining this with AppointmnetStep1
class AppointmentsAlerterStep1
  class << self
    def schedule_alerts
      upcoming_appts = Appointment.confirmed.with_alerts.upcoming.includes(:user)

      upcoming_appts.find_each do |appt|
        next if appt.user&.alert_settings&.empty?

        check_alert_valid_hour(appt, 1) if appt.is_1_hour_sent_at.nil?
        check_alert_valid_hour(appt, 12) if appt.is_12_hour_sent_at.nil?
        check_alert_valid_hour(appt, 24) if appt.is_24_hour_sent_at.nil?
      end
    end

    private

    def check_alert_valid_hour(appt, interval)
      return unless appt&.user&.has_alert_active_at?(interval_hour: interval) && appt.starts_in?(interval.hours)

      appt.mark_alert_sent!(interval)
      send_alert(appt)
    end

    def send_alert(appt)
      msg = "You have an appointment with #{appt.stylist.scheduled_message_title}"
      msg = "#{msg} at #{appt.date_time_format('%H:%M')} on #{appt.date_time_format('%Y-%m-%d')}" if appt.date_time
      appt.each_user_device { |device_id| Notification.send_appointment_alerts(msg, appt.offer_id || 1, device_id) }
    end
  end
end
