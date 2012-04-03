require 'spec_helper'

describe Category do
  let(:devmen_org) { Organization.make!(:name => 'devmen') }

  def new_category(name)
    Category.make!(:name => name)
  end

  def new_client(company_name)
    Client.make!(:short_name => company_name, :full_name => company_name)
  end

  class << self
    def ordinal(i)
      %w( first second third fourth fifth sixth seventh eight ninth tenth )[i-1]
    end

    def counter(i)
      %w( one two three four five six seven eight nine ten )[i-1]
    end
  end

  context "with one to five categories created" do
    before {
      @categories = %w( one two three four five ).map { |name|
        new_category name
      }
    }

    context "client with categories two and four" do
      before {
        @client = new_client "Some client"
        @client.categories << @categories[1] # two
        @client.categories << @categories[3] # four
      }

      it "should have even categories included" do
        [2, 4].each do |i|
          @client.categories.include?(@categories[i-1]).should be_true
        end
      end

      it "should have no odd categories included" do
        [1, 3, 5].each do |i|
          @client.categories.include?(@categories[i-1]).should_not be_true
        end
      end
    end

    context "three clients, each having categories from one to its index" do
      def new_client_with_categories(name, *cats)
        new_client(name).tap { |client|
          cats.each { |idx|
            client.categories << @categories[idx - 1]
          }
        }
      end

      before {
        @client1 = new_client_with_categories "First",  1
        @client2 = new_client_with_categories "Second", 1, 2
        @client3 = new_client_with_categories "Third",  1, 2, 3
      }

      (1..3).each { |i|
        it "#{ordinal(i)} category should have #{counter(4 - i)} clients" do
          @categories[i-1].clients.size.should == 4 - i
        end
      }
    end

    context "three tasks, each having categories from one to its index" do
      def new_task_with_categories(*cats)
        Task.make!.tap { |task|
          cats.each { |i|
            task.categories << @categories[i - 1]
          }
        }
      end

      before {
        @task1 = new_task_with_categories 1
        @task2 = new_task_with_categories 1, 2
        @task3 = new_task_with_categories 1, 2, 3
      }

      (1..3).each { |i|
        it "#{ordinal(i)} category should have #{counter(4 - i)} tasks" do
          @categories[i-1].tasks.size.should == 4 - i
        end
      }
    end

    context "three meetings, each having categories from one to its index" do
      def new_meeting_with_categories(*cats)
        Meeting.make!.tap { |task|
          cats.each { |i|
            task.categories << @categories[i - 1]
          }
        }
      end

      before {
        new_meeting_with_categories 1
        new_meeting_with_categories 1, 2
        new_meeting_with_categories 1, 2, 3
      }

      (1..3).each { |i|
        it "#{ordinal(i)} category should have #{counter(4 - i)} meetings" do
          @categories[i-1].meetings.size.should == 4 - i
        end
      }
    end

    context "three contacts, each having categories from one to its index" do
      def new_contact_with_categories(*cats)
        Contact.make!.tap { |contact|
          cats.each { |i|
            contact.categories << @categories[i - 1]
          }
        }
      end

      before {
        new_contact_with_categories 1
        new_contact_with_categories 1, 2
        new_contact_with_categories 1, 2, 3
      }

      (1..3).each { |i|
        it "#{ordinal(i)} category should have #{counter(4 - i)} contacts" do
          @categories[i-1].contacts.size.should == 4 - i
        end
      }
    end

    context "mixing client, task and meeting in one category" do
      before {
        @category = @categories.first
        Client.make!.tap { |client| client.categories << @category }
        Task.make!.tap { |task| task.categories << @category }
        Meeting.make!.tap { |meeting| meeting.categories << @category }
      }

      it "category should have only one client" do
        @category.clients.size.should == 1
      end

      it "category should have only one task" do
        @category.tasks.size.should == 1
      end

      it "category should have only one meeting" do
        @category.meetings.size.should == 1
      end
    end
  end
end
