require 'spec_helper'

describe "as an organization user" do
  let(:org)    { Organization.make! }
  let(:user)   { User.make!(:organization => org).tap { |user| user.confirm! } }
  let(:client) { Client.make!(:organization => org, :user_id => user) }

  shared_examples_for "editable client form" do
    it "client form should be displayed" do
      page.should have_selector "form"
    end
  end

  shared_examples_for "client form with common block" do
    it "client form should have short_name input" do
      page.should have_selector "#client_short_name"
    end

    it "client form should have full_name input" do
      page.should have_selector "#client_full_name"
    end

    it "client form should have user_id select" do
      page.should have_selector "#client_user_id"
    end

    it "client form should have category_tokens select" do
      page.should have_selector "#act-client-category"
    end
  end

  shared_examples_for "client form with expandable block" do
    it "client form should have a link to add more phone numbers" do
       page.should have_selector "span.addBtn"
    end
  end

  shared_examples_for "client form with buttons" do
    it "client form should have buttons block" do
        page.should have_selector "fieldset.buttons"
    end
  end

  context "signed in with valid credentials" do
    before do
      Capybara.app_host = "http://#{org.name}.lvh.me"
      visit "/"
      mock_search_results
      sign_in(org, user)
    end

    context "creating client" do
      before { visit new_client_path } #go Client, :new }

      it_should_behave_like "editable client form"
      it_should_behave_like "client form with common block"
      it_should_behave_like "client form with buttons"

      it "buttons block should have submit button" do
        page.should have_selector "input#dlg-save"
      end
      it "buttons block should have canceln button" do
        page.should have_selector "input#dlg-cancel"
      end
    end # creating client

    context "displaying client" do
      before { visit client_path(client) }

      it_should_behave_like "editable client form"
      it_should_behave_like "client form with common block"
      it_should_behave_like "client form with expandable block"
      it_should_behave_like "client form with buttons"

      it "buttons block should have submit button" do
        page.should have_selector "input#save"
      end
      it "buttons block should have cancel button" do
        page.should have_selector "input#cancel"
      end
    end # displaying client
  end
end
