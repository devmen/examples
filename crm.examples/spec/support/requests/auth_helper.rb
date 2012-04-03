# encoding: utf-8

def sign_in(organization, user, password = 'qweqwe')
  visit "http://#{organization.name}.lvh.me/"

  fill_in 'E-mail', :with => user.email
  fill_in 'Пароль', :with => password
  click_button 'Войти'
end

def mock_search_results
  @mock_results = mock("search_result")
  @mock_results.stub(:total_entries){||0}
  @mock_results.stub(:sort){||[]}

  ThinkingSphinx.stub(:search) {||@mock_results}
end
