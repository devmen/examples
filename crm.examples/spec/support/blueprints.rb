require 'machinist/active_record'

Address.blueprint do
  city         { Faker::Address.city              }
  street       { Faker::Address.street_name       }
  house_number { Faker::Address.secondary_address }
end

Client.blueprint do
  organization
  user

  short_name { Faker::Company.suffix }
  full_name  { Faker::Company.name << sn   }
end

Contact.blueprint do
  user
  client
  office

  surname { Faker::Name.last_name  }
  name    { Faker::Name.first_name }
end

Lead.blueprint do
  organization
  user
  phone_number

  surname      { Faker::Name.last_name  << sn  }
  name         { Faker::Name.first_name << sn  }
  company_name { Faker::Company.name           }
end

LegalEntity.blueprint do
  client
  user

  name { Faker::Name }
end

Meeting.blueprint do
  organization
  user

  title          { Faker::Lorem.word << sn }
  status         { 'planned'               }
  frequency      { 'daily'                 }
  start_datetime { DateTime.now - 1.day    }
  end_datetime   { DateTime.now            }
end

Office.blueprint do
  user
  client
  address

  name { 'Office name' }
end

Organization.blueprint do
  name           { "organization-#{sn}" }
  structure_type { 'simple' }
end

PhoneNumber.blueprint do
  name  { 'Phone name'  }
  phone { '8-888-88-88' }
end

Task.blueprint do
  organization
  user

  title         { Faker::Lorem.word << sn }
  start_date    { Date.today - 1.day      }
  end_date      { Date.today              }
  reminder_time { Time.now + 1.minute     }
end

User.blueprint do
  organization

  email    { "user#{sn}@example.com" }
  password { 'qweqwe'                }
  surname  { Faker::Name.last_name   }
  name     { Faker::Name.first_name  }
  role     { 'administrator'         }
  position { 'director'              }
end

EmailReference.blueprint do
  email { "email#{sn}@reference.com" }
end

ImportantDate.blueprint do
  # Attributes here
end

Categorization.blueprint do
  # Attributes here
end

Category.blueprint do
  # Attributes here
end

Emailer.blueprint do
  user
  organization

  title    { 'Test title' }
  body     { Faker::Lorem.paragraph }
  sign     { 'Ivanov iv@a.com' }
  email_to { 'email@email.com' }
end

EmailSign.blueprint do
  user
  body {'Ivanov iv@a.com'}
end

Call.blueprint do
  organization
  user

  title           { Faker::Lorem.word << sn }
  note            { 'Gi-gi' }
  start_datetime  { Time.now + 1.day }
  reminder_time   { Time.now + 1.minute  }
end

ActivityFeed.blueprint do
  # Attributes here
end

CustomersFeed.blueprint do
  # Attributes here
end
