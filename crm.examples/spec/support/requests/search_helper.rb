# encoding: utf-8

def search(field, org_name = 'devmen')
  visit "http://devmen.lvh.me/"

  fill_in 'Искать:', :with => field
  click_button 'Искать'
end
