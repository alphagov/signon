# Decision Record: Pass anonymised user IDs to publishing apps and analytics

## Context

We want to be able to reason about repeat usage of publishing applications at the level of individual users.

We don't want to track full user IDs, because that would be bad for privacy.

Instead, we'd like to use "anonymised" IDs, which persist for a given user, but can't easily be traced back to
as specific person.

## Problem

The threat model here is primarily internal users, with access to analytics. We do want these people to be able
to answer questions like "how many unique users have used Whitehall this month?", but we do not want them to be able
to answer questions like "which named individual on my team has done the most work this month?"

Anonymising the user IDs should make it reasonably hard (although not impossible) to work backwards from an anonymised
ID to a named individual.

## Solution

### Anonymising the user ID

Signon already generates a unique ID for each user, which is a random UUID. We will combine this with a secret known
only to the applications, and hash the result using SHA256. We'll truncate the hash to 16 hexadecimal characters, which
is long enough to avoid collisions ([source](https://github.com/alphagov/signon/pull/3983#discussion_r2284680904))
while not taking up too much space.

Calculation of the anonymous user ID will look something like this:

```ruby
require "digest"
require "json"

Digest::SHA2.hexdigest(JSON.dump([ user.uid, ENV["ANONYMOUS_USER_ID_SECRET"] ]))[..16]
```
(Note: using JSON.dump to combine values before hashing them is [considered better practice than concatenation](https://jameshfisher.com/2018/01/09/how-to-hash-multiple-values/)
because the combine function needs to be "injective" to avoid collisions like `hash("ab" + "cd") == hash("a" + "bcd")`).

We chose SHA256 as the hashing algorithm rather than something like BCrypt of PBKDF2 because:

- SHA256 implementations are ubiquitous, including in the ruby standard library without the need for any gems or
  external dependencies such as openssl.
- the number of users we have is small, so there's no realistic defence against brute forcing the anonymous ids by
  calculating them for every user, even with a deliberately slow hash function.
- SHA256 is fast, and since there's no benefit to being slow, we may as well go fast

### Providing the anonymised user ID to applications

We could have Signon generate anonymous user IDs, or we could have each application generate the IDs themselves using a
shared secret.

The advantage of having Signon generate the ID is that we only need the secret to be available in one application, which
simplifies the infrastructure and somewhat reduces the risk of the secret leaking. The disadvantages are complexity of
implementation, and risk that an application may accidentally store the anonymous ID in the database (effectively
de-anonymising it).

On balance, we prefer to have each application generate the IDs using a shared secret - trading off some additional
complexity in the infrastructure for simplicity of implementation in the code.

### Sending the anonymised user ID to the data layer (and analytics)

The analytics code in `govuk_publishing_components` already has
[support for `user_id`](https://github.com/alphagov/govuk_publishing_components/blob/main/app/assets/javascripts/govuk_publishing_components/analytics-ga4/ga4-page-views.js#L75).

Providing a meta tag with `<meta name="govuk:user-id" content="e3b0c44298fc1c149">` should be all we need to populate
the data layer.

A performance analyst will need to configure tag manager to send the data onwards to google analytics.

## Consequences

1. It will be possible to correlate analytics events to anonymous users
2. De-anonymising users will be reasonably difficult, requiring access to read secrets from the infrastructure and a
   list of user uids
3. Applications will need a new shared secret, which we'll need to provide via the helm charts
4. We will not need to pass the anonymous id around as a separate field in the token, or store it in session, as it will
   be derived from user.uid.
5. If the shared secret were leaked, we would be able to change it and a new set of anonymous ids would be generated

