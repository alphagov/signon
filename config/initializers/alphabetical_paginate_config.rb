ALPHABETICAL_PAGINATE_CONFIG = {
  db_field: "users.name",
  numbers: false,
  others: false,
  include_all: false,
  js: false,
  bootstrap3: true
}

ALPHABETICAL_PAGINATE_CONFIG[:db_mode] = true if Signonotron2.mysql?
