# QUIZ I . 2023 #unit Rails #
## Fat Model, Skinny Controller ##

** Rails 6 or 7 **

Models are a core component of the MVC architecture where **all the business logic is supposed to go**. Saying ‘supposed to’ because it’s not always best to put everything in the model.

### The Problem? ###

Whoever coined the ‘Skinny Controllers, Fat Models’ convention for MVC frameworks forgot to emphasize on a model’s **single responsibility principle**. Sure keep your controllers nice and clean but don’t do it at the expense of your model handling business logic that it’s not supposed to. In Rails, for instance, **Active Record Models should only have 1 responsibility: Active Record**. That’s it. It should not, for example, be responsible for sending emails to or about the object it encapsulates.

### Say No to ‘Skinny Controller, Fat Model’ and Yes to ‘Skinny Controller, Smart Model with Single Responsibility’ ###

This application is related to an appointment management portal. Stylists (hairdressers) add Offers and Users avail these offers to book an Appointment through a mobile app and a website. All new appointments are visible in a dashboard from where the Admin (portal administrator) follows up with the user via phone call to confirm their booking. Once approved, Stylists can see confirmed appointments in their dashboard.

### Objectives ###

The purpose of this exercise is to give responsibility to the model, isolate the necessary code and redo some code using the most known patterns.

There are several ways to do it, the objective is to see how developers think about their problems and how they organize them. This sharing of knowledge is essential for everyone, both for the projects we are part of and for learning within the rails stack

### so what's the challenge? ###

* Refactoring the appointment.rb model

the idea is not to get the project running but based on the initial model presented, restructure it.

### How to do it ###

the most important thing is to leave the line of thought inside the pull request or in a readable way so that the code that will be discussed can be analyzed, the best practices and the less usual ones

You can:

* create different files for different iterations
* ex: appointment_step_1.rb
* ex: appointment_step_2.rb 
* ex: appointment_step_....rb 
* ex: appointment.rb 

**OR** 

create a README.me file that can go into the project indicating the whole line of thought as the steps

All auxiliary files must always be identified in the solution

### Who can do it? ###

* A team 
* Individual

### Times ###

open a Pull Request to the main branch ##ON## 24th of February or Fork the repository and give #rails unit team the proper access to read it. it will always be considered the latest version of the existing code in the case of PR.

### The Quiz ###

In the end it's about learning, getting solutions copied from the web will not help any developer to get better solutions.We will get a discussion about all solutions,finding the positive points of both, we are not looking to have the best code but to learn the best solutions.

Thanks for all
**#rails unit**

***Let's do some code ಠ_ಠ ***
