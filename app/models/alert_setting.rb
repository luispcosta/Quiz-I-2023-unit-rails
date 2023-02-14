class AlertSetting < ApplicationRecord
  belongs_to :user
  validates :hours_beforehand, uniqueness: true, scope: :user_id

  def has_alert_active_hours_before?(num)
    hours_beforehand == num
  end
end
