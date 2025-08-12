# Decision Record: Pass anonymised user ids to publishing apps and analytics

## Context

We want to be able to reason about repeat usage of publishing applications at the level of individual users.

We don't want to track full user ids, because that would be bad for privacy.

Instead, we'd like to use "anonymised" IDs, which persist for a given user, but can't easily be traced back to
as specific person.

## Problem

The threat model here is primarily internal users, with access to analytics. We do want these people to be able
to answer questions like "how many unique users have use Whitehall this month?", but we do not want them to be able
to answer questions like "which named individual on my team has done the most work this month?"

Anonymising the user ids makes it hard (but not impossible) to work backwards from an anonymised id to a named
individual.

## Solution

### Anonymising the user id

#### Use SHA2

```ruby
require "openssl"
OpenSSL::PKCS5.pbkdf2_hmac_sha1(u.uid, u.password_salt, 1000, 32).unpack1('H*')
```

```ruby
require "digest"
Digest::SHA2.hexdigest(u.uid + ENV["ANONYMISED_USER_ID_SECRET"])[0..20]
```

### Sending the anonymised user id to other applications

Signon link below includes a pseudo-implementation of anonomysing the User ID, and then presents that to the other applications.

https://github.com/alphagov/signon/compare/spike-user-id-tracking?expand=1

There is an open question about whether the anonomysed user IDs persist in databases.

https://github.com/alphagov/gds-sso/compare/spike-user-id-tracking?expand=1

### Sending the anonymised user id to the data layer

## Steps to implement

## Consequences

