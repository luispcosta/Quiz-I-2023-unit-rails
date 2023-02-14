# Assumptions

* We are using postgres as the database.
* Running rails version 7
* There can't be two appointments on the same day and hour offering the same offer.
* The notifications regarding status updates are not critical (i.e, there's no issue if a notification is not sent)
* A user can have all three kind of alerts active at once (1h before, 12h before, 24h before)
* The class `AppointmentsAlerter` would be called every minute in a sidekiq scheduler (for example, using a Heroku Scheduler)
  * Since we don't know the volume of data we're dealing with, we assume that 1 minute would be enough to process all the upcoming
    appointments. If 1 minute isn't enough, we'd have to parallelize the alerts: for example, appointments alerter would instead
    schedule individual alerter workers for each apppointment.
  * In the scenario where we use the version of AppointmentStep1, if we'd rename the columns `is_x_hour` to `is_x_hour_sent_at`, we could monitor the values of these columns
    to check for drifts. If the drift began to widen, we'd know that the system is not scaling, and we'd have to investigate
    on further ways to scale the system.
* In the `AppointmentsAlerter` we assume that it is more important not to send repeated alerts than it is to send repeated alerts
for the same appointment/user.
* `Notification.send_appointment_alerts` is non blocking and never fails/raises an exception.
* `Notification.send_appointment_alerts` doesn't send repeated alerts.
  * If not, AppointmentStep1 isn't dealing with that case. In AppointmentStep2 we could use the table `appointment_alerts` to prevent sending repeated alerts.

# Things we'd refactor (not shown in the PR)

* The application timezone would be configured in the [rails app config](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html)

```ruby
config.time_zone = "Asia/Karachi"
```

* A possible solution to have alerts more flexible, would be to create a table called `appointment_alerts` (appointment_step_2).
  * This table would contain a field called `type` which would be treated as a enum in the code.
  * To check if a user already received a certain type of alert, we'd just need to check if an alert existed for a certain type (type 0 could be the type of alert 1 hour before, 1 for the alert 12 hours before, etc.)

* The barcode could be refactored even more to make it more generic/re-usable (if needed):
  - Extract file system management code to another class
  - Pass a flag to indicate if we should generate the barcode if it doesn't exist (right now, it always does this)
  - Pass a barcode symboloogy as a dependency injection (instead of always using Barby::Code128B)
  - Specify the image file type (png, jpg, etc)

* If `Notification.send_appointment_status_change_notification` and `Notification.send_appointment_alerts` could fail:
  * It wouldn't be a good idea to have it be called inside the rails callbacks (in order not to prevent commit from failing), and it would have to be called from another place.
  * We'd have to keep a separate list of retries. The retries would need to be discarded if their time has already passed.
  * We could also call these methods inside a `after_commit` callback (were applicable) if we wanted to keep them inside the model.
