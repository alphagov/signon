require 'test_helper'
require Rails.root + 'lib/numbers/numbers_csv'

class NumbersCsvTest < ActiveSupport::TestCase

  def setup
    FactoryGirl.create(:admin_user, email: 'admin_user@admin.example.com')
    3.times {|i| FactoryGirl.create(:user) }
  end

  def teardown
    `rm ./numbers.csv`
  end

  test "csv contains accounts count" do
    NumbersCsv.generate
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count", "total", "4"]
  end

  test "csv contains counts by role" do
    NumbersCsv.generate
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by role", "admin", "1"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by role", "normal", "3"]
  end

  test "csv contains counts by account state" do
    User.last.suspend('test')

    NumbersCsv.generate

    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by state", "active", "3"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by state", "suspended", "1"]
  end

  test "csv contains counts by application access" do
    app = FactoryGirl.create(:application, name: "WhiteCloud")
    FactoryGirl.create(:supported_permission, name: "write", application: app)
    User.first.grant_permission(app, "write")

    NumbersCsv.generate

    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by application", "WhiteCloud", "1"]
  end

  test "csv contains counts by organisation" do
    org = FactoryGirl.create(:organisation, name: "Ministry of Digital")
    org.users << User.first

    NumbersCsv.generate

    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by organisation", "Ministry of Digital", "1"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by organisation", "None assigned", "3"]
  end

  test "csv contains counts by days of inactivity" do
    [7, 15].each_with_index {|days_count, i| User.all[i].update_attribute(:current_sign_in_at, days_count.days.ago) }

    NumbersCsv.generate

    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by days inactive", "7+", "2"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by days inactive", "15+", "1"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by days inactive", "30+", "0"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by days inactive", "60+", "0"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by days inactive", "90+", "0"]
  end

  test "csv contains counts by email domain" do
    NumbersCsv.generate
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by email domain", "admin.example.com", "1"]
    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by email domain", "example.com", "3"]
  end

  test "csv contains counts by application access per organisation" do
    app = FactoryGirl.create(:application, name: "WhiteCloud")
    FactoryGirl.create(:supported_permission, name: "write", application: app)
    User.first.grant_permission(app, "write")

    org = FactoryGirl.create(:organisation, name: "Ministry of Digital")
    org.users << User.first

    NumbersCsv.generate

    assert CSV.parse(File.read(Rails.root + 'numbers.csv')).include? ["Accounts count by application per organisation", "Ministry of Digital", "WhiteCloud", "1"]
  end

end
