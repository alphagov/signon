require 'test_helper'
require Rails.root + 'lib/numbers/numbers_csv'

class NumbersCsvTest < ActiveSupport::TestCase

  def setup
    FactoryGirl.create(:admin_user, email: 'admin_user@admin.example.com', name: "Winston")
    FactoryGirl.create_list(:user, 3)
  end

  def teardown
    `rm ./numbers.csv`
  end

  def numbers_csv
    CSV.parse(File.read(Rails.root + 'numbers.csv'))
  end

  test "csv contains accounts count" do
    NumbersCsv.generate
    assert numbers_csv.include? ["Accounts count", "total", "4"]
  end

  test "csv contains counts by account state" do
    User.last.suspend('test')

    NumbersCsv.generate

    assert numbers_csv.include? ["Accounts count by state", "active", "3"]
    assert numbers_csv.include? ["Accounts count by state", "suspended", "1"]
  end

  test "csv contains counts by role" do
    NumbersCsv.generate
    assert numbers_csv.include? ["Active accounts count by role", "admin", "1"]
    assert numbers_csv.include? ["Active accounts count by role", "normal", "3"]
  end

  test "csv contains admin and superadmin user names" do
    FactoryGirl.create(:admin_user, email: "maggie@gov.uk", name: "Margaret", role: "superadmin")
    FactoryGirl.create(:admin_user, email: "dave@gov.uk", name: "David", role: "admin")

    NumbersCsv.generate

    assert numbers_csv.include? ["Active admin user names", "admin", "David <dave@gov.uk>, Winston <admin_user@admin.example.com>"]
    assert numbers_csv.include? ["Active admin user names", "superadmin", "Margaret <maggie@gov.uk>"]
  end

  test "csv contains counts by application access" do
    app = FactoryGirl.create(:application, name: "WhiteCloud")
    FactoryGirl.create(:supported_permission, name: "signin", application: app)
    User.first.grant_permission(app, "signin")

    NumbersCsv.generate

    assert numbers_csv.include? ["Active accounts count by application", "WhiteCloud", "1"]
  end

  test "csv contains counts by organisation" do
    org = FactoryGirl.create(:organisation, name: "Ministry of Digital")
    org.users << User.first

    NumbersCsv.generate

    assert numbers_csv.include? ["Active accounts count by organisation", "Ministry of Digital", "1"]
    assert numbers_csv.include? ["Active accounts count by organisation", "None assigned", "3"]
  end

  test "csv contains counts by days since last sign-in" do
    all_users = User.all
    [6.days.ago, 14.days.ago, 1.minute.ago].each_with_index {|time, i| all_users[i].update_attribute(:current_sign_in_at, time) }

    NumbersCsv.generate

    assert numbers_csv.include? ["Accounts count by days since last sign in", "0 - 7", "2"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "7 - 15", "1"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "15 - 30", "0"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "30 - 45", "0"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "45 - 60", "0"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "60 - 90", "0"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "90 - 180", "0"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "180 - 10000000", "0"]
    assert numbers_csv.include? ["Accounts count by days since last sign in", "never signed in", "1"]
  end

  test "csv contains counts by how often users have signed in" do
    all_users = User.all
    [0, 1, 2, 123].each_with_index {|count, i| all_users[i].update_attribute(:sign_in_count, count) }

    NumbersCsv.generate

    assert numbers_csv.include? ["Accounts count how often user has signed in", "0 time(s)", "1"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "1 time(s)", "1"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "2 - 5", "1"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "5 - 10", "0"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "10 - 25", "0"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "25 - 50", "0"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "50 - 100", "0"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "100 - 200", "1"]
    assert numbers_csv.include? ["Accounts count how often user has signed in", "200 - 10000000", "0"]
  end

  test "csv contains counts by email domain" do
    NumbersCsv.generate
    assert numbers_csv.include? ["Active accounts count by email domain", "admin.example.com", "1"]
    assert numbers_csv.include? ["Active accounts count by email domain", "example.com", "3"]
  end

  test "csv contains counts by application access per organisation" do
    app = FactoryGirl.create(:application, name: "WhiteCloud")
    FactoryGirl.create(:supported_permission, name: "signin", application: app)
    User.first.grant_permission(app, "signin")

    org = FactoryGirl.create(:organisation, name: "Ministry of Digital")
    org.users << User.first

    NumbersCsv.generate

    assert numbers_csv.include? ["Active accounts count by application per organisation", "Ministry of Digital", "WhiteCloud", "1"]
  end

end
