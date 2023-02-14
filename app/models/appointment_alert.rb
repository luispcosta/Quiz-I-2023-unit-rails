class AppointmentAlert < ApplicationRecord
  belongs_to :appointment

  enum type: {
    0 => :hour,
    12 => :half_a_day,
    24 => :day
  }
end
