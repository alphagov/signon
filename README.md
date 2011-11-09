## Calendars

A Rails application to format and display calendar data, starting with [Bank Holidays](http://www.direct.gov.uk/en/Employment/Employees/Timeoffandholidays/DG_073741), in a clearer and more accessible format, along with JSON and iCal exports of the data.

### Usage

Each type of calendar (e.g. daylight saving, bank holidays) is known as a _scope_. A scope has its own view templates, JSON data source and primary route.

JSON data files are stored in `lib/data/bank_holidays.json`, with a `divisions` hash for separate data per region (e.g. `england-and-wales`, `scotland` or `ni`).

