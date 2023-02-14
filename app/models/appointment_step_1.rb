class AppointmentStep1 < ApplicationRecord
  enum status: {
    pending: 0,
    confirmed: 1,
    canceled: 2,
    rescheduled: 3
  }, default: :pending

  enum call_status: {
    not_called: 0,
    called: 1,
    no_answer: 2
  }, default: :not_called

  belongs_to :offer
  belongs_to :stylist
  belongs_to :user

  validates :user_id, presence: true
  validates :offer_id, presence: true

  validate :no_same_appointment_same_date_and_time

  scope :with_alerts, -> { where(is_alert: true) }
  scope :upcoming,    -> { where.not(date_time: nil).where(date_time: Time.zone..) }

  after_create :alert_on_appointment_creation
  after_create :generate_barcode

  before_create :add_initial_call_status

  before_update :status_change_alert
  before_update :refund_if_cancelled_by_admin

  def no_same_appointment_same_date_and_time
    other_appt_booked_exists = date_time && exists?(status: %i[pending confirmed], offer_id: offer_id, date_time: date_time.beginning_of_minute..date_time.end_of_minute)
    errors.add(:date, 'Other appointment already booked for this date and hour') if other_appt_booked_exists
  end

  def toggle_call_status!
    if not_called?
      called!
    elsif called?
      no_answer!
    else
      not_called!
    end
  end

  def refund_if_cancelled_by_admin
    self.allow_refund = true if cancelled_by_admin?
  end

  def alert_on_appointment_creation
    return if is_private?
    return unless pending? && date.present?

    msg = AppointmentMessage.new(self).build('pending_status_alert')
    each_user_device { |device_id| Notification.send_appointment_status_change_notification(msg, 1, device_id) }
  end

  def status_change_alert
    return if is_private?
    return unless status_changed?

    offer = 1
    appointment_message = AppointmentMessage.new(self)
    case status
    when :confirmed
      msg = appointment_message.build('confirm_status_alert')
      offer = offer_id if offer_id
    when :canceled
      msg = appointment_message.build('cancel_status_alert')
    when :rescheduled
      msg = appointment_message.build('reschedule_status_alert')
    end

    each_user_device { |device_id| Notification.send_appointment_status_change_notification(msg, offer, device_id) }
    self.status_changed_at = Time.zone.now
  end

  def mark_alert_sent!(interval)
    case interval
    when 1 then self.is_1_hour_sent_at = Time.zone.now
    when 12 then self.is_12_hour_sent_at = Time.zone.now
    when 24 then self.is_24_hour_sent_at = Time.zone.now
    else
      raise ArgumentError, 'only 1, 12 or 24 accepted'
    end

    save!
  end

  def starts_in?(duration)
    (Time.zone.now + duration).strftime("%H:%M:00") == date_time
  end

  def barcode
    @barcode ||= Barcode.new("appointment#{id}").generate
  end

  def date_time_format(format)
    date_time.strftime(format)
  end

  def each_user_device
    user.user_devices.each { |user_device| yield user_device.device_id }
  end
end
