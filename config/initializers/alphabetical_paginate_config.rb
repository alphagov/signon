ALPHABETICAL_PAGINATE_CONFIG = {
  db_field: "users.name",
  numbers: false,
  others: false,
  include_all: false,
  js: false,
  bootstrap3: true
}.freeze

ALPHABETICAL_PAGINATE_CONFIG[:db_mode] = true if Signon.mysql?
