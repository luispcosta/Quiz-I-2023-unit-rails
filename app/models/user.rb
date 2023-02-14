class User < ApplicationRecord
  has_many :appointments
  has_many :alert_settings

  def has_alert_active_at?(hours_before:)
    alert_settings.any? { |setting| setting.has_alert_active_hours_before?(hours_before) }
  end
end
