class Stylist < ApplicationRecord
  has_many :appointments

  def scheduled_message_title
    @scheduled_message_title ||= build_title(scheduled_messages_translations)
  end

  def status_message_title
    @status_message_title ||= build_title(status_messages_translations)
  end

  private

  def scheduled_messages_translations
    @scheduled_messages_translations ||= translations&.first
  end

  def status_messages_translations
    @status_messages_translations ||= translations&.last
  end

  def build_title(translations)
    "#{translations&.title} #{translations&.name}"
  end
end
