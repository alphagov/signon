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

#### Option 1 - Use an encryption algorithm like AES

Don't really need an encryption algorithm, but probably easy to do.

#### Option 2 - Use a hashing function like PBKDF2 or SHA2

```ruby
require "openssl"
OpenSSL::PKCS5.pbkdf2_hmac_sha1(u.uid, u.password_salt, 1000, 32).unpack1('H*')
```

```ruby
require "digest"
Digest::SHA2.hexdigest(u.uid + ENV["ANONYMISED_USER_ID_SECRET"])[0..20]
```



### Sending the anonymised user id to other applications

### Sending the anonymised user id to the data layer

## Steps to implement

## Consequences

