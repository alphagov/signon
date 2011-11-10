## Calendars

A Rails application to format and display calendar data, starting with [Bank Holidays](http://www.direct.gov.uk/en/Employment/Employees/Timeoffandholidays/DG_073741) and Daylight Savings Time, in a clearer and more accessible format, along with JSON and iCal exports of the data.

### Usage

Each type of calendar (e.g. daylight saving, bank holidays) is known as a _scope_. A scope has its own view templates, JSON data source and primary route.

JSON data files are stored in `lib/data/<scope>.json`, with a `divisions` hash for separate data per region (`united-kingdom`, `england-and-wales`, `scotland` or `ni`).
      
### Data Format

Each scope's data file contains a list of divisions, containing a list of calendars, each with a list of events:

	{ "divisions": {
		"england-and-wales": [{
			"2011": [{
				"title": "New Year's Day",
				"date": "02/01/2011",
				"notes": "Substitute day"
			}]
		}]
	}}

### API

Each calendar has a series of formats and endpoints at which data can be accessed:

* `/<scope>/<division>-<year>.<format>` - calendar for events in a specific year for a division, available as `json` or `ics`
* `/<scope>/<division>.<format>` - calendar for all events in a division regardless of year, available as `json` or `ics`
* `/<scope>.<format>` - entire scope dataset, all divisions, their calendars and events, only available as `json` 