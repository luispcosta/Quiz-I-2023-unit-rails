class Appointment < ApplicationRecord

    scope :pending, -> { where(status: APPOINTMENT_STATUS[0]) }
    scope :rescheduled, -> { where(status: APPOINTMENT_STATUS[3]) }
    scope :canceled, -> { where(status: APPOINTMENT_STATUS[2]) }
    scope :confirmed, -> { where(status: APPOINTMENT_STATUS[1]) }
  
    belongs_to :offer
    belongs_to :stylist
    belongs_to :user
  
    validates :user_id, presence: true
    validates :offer_id, presence: true
    validates_uniqueness_of :time, scope: [:offer_id, :date], conditions: -> { where.not(status: [APPOINTMENT_STATUS[2], APPOINTMENT_STATUS[3]]) }, if: Proc.new { |a| a.date and a.time }
  
    before_validation :appointment_date_time
    before_create :add_initial_call_status
    after_create :alert_on_appointment_creation
    before_update :status_change_alert
    after_create :generate_barcode
    before_update :refund_if_cancelled_by_s_or_a
  
    def appointment_date_time
      if self.date_time.present?
        self.date = self.date_time.to_date
        self.time = self.date_time.to_time.strftime("%H:%M")
      end
    end
  
    def add_initial_call_status
      self.call_status = 'not called'
    end
  
    def toggle_call_status
      if self.call_status == 'not called'
        self.call_status = 'called'
      elsif self.call_status == 'called'
        self.call_status = 'no answer'
      elsif self.call_status == 'no answer'
        self.call_status = 'not called'
      else
        self.call_status = 'not called'
      end
      self.save
    end
  
    def refund_if_cancelled_by_s_or_a
      if self.cancelled_by_admin?
        self.allow_refund = true
      end
    end
  
    #notifications about appointment state [pending, confirmed, cancelled, rescheduled]
    def alert_on_appointment_creation
      if self.status == APPOINTMENT_STATUS[0] and !self.date.blank?
        user = User.find(self.user_id) if !self.is_private?
        if user.present?
          msg = I18n.t('pending_status_alert', locale: 'ur')
  
          if self.date and self.time
            msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', self.date.strftime("%d-%m-%Y")).gsub('tt', self.time.strftime("%l:%M %p"))
          else
            msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', '').gsub('tt', '')
          end
  
          user.user_devices.each do |user_device|
            device_id = user_device.device_id
            Notification.send_appointment_status_change_notification(msg,1, device_id)
          end
        end
      end
    end
  
    def status_change_alert
      appointment = Appointment.find(self.id) if self.persisted?
      user = User.find(self.user_id) if !self.is_private?
      if appointment && (appointment.status != self.status) && user.present?
        if self.status == APPOINTMENT_STATUS[1] # confirmed
  
          msg = I18n.t('confirm_status_alert', locale: 'ur')
          if self.date and self.time
            msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', self.date.strftime("%d-%m-%Y")).gsub('tt', self.time.strftime("%l:%M %p"))
          else
            msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', '').gsub('tt', '')
          end
  
          user.user_devices.each do |user_device|
            device_id = user_device.device_id
            key = 1
            if appointment.offer_id and !appointment.offer_id.blank?
              key = appointment.offer_id
            end
            Notification.send_appointment_status_change_notification(msg,key, device_id)
          end
  
        elsif self.status == APPOINTMENT_STATUS[2] # canceled
          msg = I18n.t('cancel_status_alert', locale: 'ur')
  
          if self.date and self.time
            msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', self.date.strftime("%d-%m-%Y")).gsub('tt', self.time.strftime("%l:%M %p"))
          else
            msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', '').gsub('tt', '')
          end
  
  
          user.user_devices.each do |user_device|
            device_id = user_device.device_id
            Notification.send_appointment_status_change_notification(msg,1, device_id)
          end
        elsif self.status == APPOINTMENT_STATUS[3] #rescheduled
          if self.date and self.time
            msg = I18n.t('reschedule_status_alert', locale: 'ur')
  
            if self.date and self.time
              msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', self.date.strftime("%d-%m-%Y")).gsub('tt', self.time.strftime("%l:%M %p"))
            else
              msg = msg.gsub('stylist', ("#{self.stylist.translations.last.title.present? ? self.stylist.translations.last.title+' ': nil}#{self.stylist.translations.last.name}")).gsub('dd', '').gsub('tt', '')
            end
  
            user.user_devices.each do |user_device|
              device_id = user_device.device_id
              Notification.send_appointment_status_change_notification(msg,1, device_id)
            end
          end
        end
        self.status_changed_at = Time.now
      end
    end
  
    #alert methods: reminding user about appointments
    def self.appointment_alerts
      curr_time = Time.now.in_time_zone("Asia/Karachi")
      curr_time_1_hour = (curr_time + 1.hours).strftime("2000-01-01 %H:%M:00")
      curr_time_12_hour = (curr_time + 2.hours).strftime("2000-01-01 %H:%M:00")
      curr_time_24_hour = (curr_time + 24.hours).strftime("2000-01-01 %H:%M:00")
      user_ids = Appointment.includes(:user).where("is_alert= ? AND time >= ? AND date >= ?  AND status = ?", true, curr_time, Time.now.in_time_zone("Asia/Karachi").to_date, 'confirmed' ).collect{|app| [app.user_id]}
      user_ids.each do |id|
        user = User.find_by(id: id)
        if user.present? && user.alert_setting.present? && user.alert_setting.is_alert_1_hour?
          send_user_appointment_alert(user, curr_time_1_hour, 1 )
        end
        if user.present? && user.alert_setting.present? && user.alert_setting.is_alert_12_hour?
          send_user_appointment_alert(user, curr_time_12_hour, 12)
        end
        if user.present? && user.alert_setting.present? && user.alert_setting.is_alert_24_hour?
          send_user_appointment_alert(user, curr_time_24_hour, 24)
        end
      end
    end
  
    def self.send_user_appointment_alert(user, alert_time, alert_type)
  
      if alert_type == 1
        appointments = user.appointments.where("is_alert= ? AND time = ? AND date = ? AND status = ? AND is_1_hour = ?", true, alert_time , Time.now.in_time_zone("Asia/Karachi").to_date, 'confirmed', false ).collect{|app| [app.id]}
        appointments.each do |appointment_id|
          appointment = Appointment.find_by(id: appointment_id)
          send_appointment(user, appointment)
          appointment.update(is_1_hour: true)
        end
      elsif alert_type == 12
        appointments = user.appointments.where("is_alert= ? AND time = ? AND date = ? AND status = ? AND is_12_hour = ?", true, alert_time , Time.now.in_time_zone("Asia/Karachi").to_date, 'confirmed', false ).collect{|app| [app.id]}
        appointments.each do |appointment_id|
          appointment = Appointment.find_by(id: appointment_id)
          send_appointment(user, appointment)
          appointment.update(is_12_hour: true)
        end
      elsif alert_type == 24
        appointments = user.appointments.where("is_alert= ? AND time = ? AND date = ? AND status = ? AND is_24_hour = ?", true, alert_time , Time.now.in_time_zone("Asia/Karachi").to_date, 'confirmed', false ).collect{|app| [app.id]}
        appointments.each do |appointment_id|
          appointment = Appointment.find_by(id: appointment_id)
          send_appointment(user, appointment)
          appointment.update(is_24_hour: true)
        end
      end
  
    end
  
    def self.send_appointment(user, appointment)
  
      msg = "You have an appointment with  #{appointment.stylist.translations.first.title+' '+ appointment.stylist.translations.first.name}"
      msg = msg+" at #{appointment.time.strftime("%H:%M")} on #{appointment.date}" if appointment.date and appointment.time
      user.user_devices.each do |user_device|
        device_id = user_device.device_id
        key = 1
        if appointment.offer_id and !appointment.offer_id.blank?
          key = appointment.offer_id
        end
        Notification.send_appointment_alerts(msg, key, device_id)
      end
  
    end
  
    #get barcode for receipt
    def generate_barcode
      #require 'barby'
      require 'barby/barcode/code_128'
      require 'barby/outputter/png_outputter'
  
      dir = File.dirname(Rails.root.join('/path_to_folder/create.log'))
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
  
      barcode = Barby::Code128B.new('appointment'+self.id.to_s)
      blob = Barby::PngOutputter.new(barcode).to_png #Raw PNG data
      File.open(Rails.root.join('/path_to_folder/'+self.id.to_s+'.png'), 'wb'){|f| f.write blob }
    end
  
    def get_barcode
      barcode = Rails.root.join('public/barcodes/appointments/a'+self.id.to_s+'.png')
      barcode_out = '/path_to_folder/'+self.id.to_s+'.png'
      unless File.exists? barcode
        self.generate_barcode
      end
      barcode_out
    end
  
  end