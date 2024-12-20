# API

There is a lightweight API endpoint for signon, which returns information about users with
given UUIDs.

## Accessing

To access the API, you must have an API-only Application set up in Signon called "Signon API".
This can be set up like so:

```shell
rake applications:create name="Signon API" description="API endpoints for user management in Signon" \
  home_uri="https://signon.integration.publishing.service.gov.uk" \
  redirect_uri="https://signon.integration.publishing.service.gov.uk" \
  api_only="true"
```

You can then create an API user in the Signon UI, grant them access to the Signon API, and 
access with the Bearer token like so:

```shell
curl --location --globoff 'https://SIGNON_DOMAIN/api/users?uuids[]=c514c7e0-a049-013d-c537-3209197caa3b' \
--header 'Authorization: Bearer YOUR_BEARER_TOKEN'
```

## Endpoints

* [`GET /api/users`](#get-apiusers)

### `GET /api/users`

Lists users for the given `uuids`

#### Query string parameters

* `uuids` (required)
  * An array of UUIDs to query for


