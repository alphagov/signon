namespace :rummager do
  desc "Reindex search engine"
  task :index => :environment do
    documents = [{
      "title"             => "When do the clocks change?",
      "description"       =>
        "In the UK the clocks go forward 1 hour at 1am on the last Sunday in "+
        "March, and back 1 hour at 2am on the last Sunday in October.",
      "format"            => "calendar",
      "link"              => "/when-do-the-clocks-change",
      "indexable_content" => %{
        This clock change gives the UK an extra hour of daylight (sometimes
        called Daylight Saving Time).  From March to October (when the
        clocks are 1 hour ahead) the UK is on British Summer Time (BST).
        From October to March, the UK is on Greenwich Mean Time (GMT).
      }
    }, {
      "title"             => "UK Bank Holidays",
      "description"       =>
        "A bank holiday is a public holiday in the United Kingdom",
      "format"            => "calendar",
      "link"              => "/bank-holidays",
      "indexable_content" => "",
    }]
    Rummageable.index documents
  end
end
