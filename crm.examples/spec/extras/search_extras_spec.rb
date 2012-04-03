# encoding: utf-8
require 'spec_helper'

class DummyClass
  extend SearchExtras
end

describe SearchExtras, :search => true do
  before(:all) { ThinkingSphinx::Test.start }
  after(:all)  { ThinkingSphinx::Test.stop  }

  context "#date_search" do
    let!(:meeting) do
      Meeting.make!(:start_datetime => DateTime.new(2011, 05, 05),
                    :end_datetime   => DateTime.new(2011, 05, 10))
    end

    let!(:task) do
      Task.make!(:start_date => Date.new(2011, 05, 05),
                 :end_date   => Date.new(2011, 05, 10))
    end

    let!(:client) do
      Client.make!(:updated_at => DateTime.new(2011, 05, 8))
    end

    context 'should search by' do
      { 'dd/mm/yyyy' => '08/05/2011',
        'dd.mm.yyyy' => '08.05.2011',
        'dd month, year' => '08 мая, 2011' }.each_pair do |msg, date|
        it msg do
         DummyClass.date_search(date, {}).should have(3).items
        end
      end
    end

    subject { DummyClass.date_search('08.05.2011', {}) }

    it 'should put all objects in one-dimensional array' do
      should include client, task, meeting
    end

    it { should be_instance_of(ThinkingSphinx::Search) }
  end
end
