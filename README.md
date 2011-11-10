## Calendars

A Rails application to format and display calendar data, starting with [Bank Holidays](http://www.direct.gov.uk/en/Employment/Employees/Timeoffandholidays/DG_073741), in a clearer and more accessible format, along with JSON and iCal exports of the data.

### Usage

Each type of calendar (e.g. daylight saving, bank holidays) is known as a _scope_. A scope has its own view templates, JSON data source and primary route.

JSON data files are stored in `lib/data/bank_holidays.json`, with a `divisions` hash for separate data per region (e.g. `england-and-wales`, `scotland` or `ni`).

### API

Each calendar has a series of formats and endpoints at which data can be accessed:

* `/<scope>/<division>-<year>.<format>` - calendar for events in a specific year for a division, available as `json` or `ics`
* `/<scope>/<division>.<format>` - calendar for all events in a division regardless of year, available as `json` or `ics`
* `/<scope>.<format>` - all divisions, their calendars and events, available as `json` 