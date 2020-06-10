# Sign-On-O-Tron and OAuth2

The GOV.UK admin and editorial systems share a single sign-on system. User
accounts are created and managed in the sign-on-o-tron application. Users
are then authorized to access any given app by use of the OAuth2 protocol.

The OAuth2 provider functionality is provided by the
[Doorkeeper ruby gem](https://rubygems.org/gems/doorkeeper). It is based on
[version 22 of the OAuth 2 specification](http://tools.ietf.org/html/draft-ietf-oauth-v2-22).
This document is intended to detail the OAuth profile in use and should be read
alongside the relevant version of the specification.

While the OAuth2 flow should be simple enough to implement directly, we have a
ruby library [gds-sso](https://github.com/alphagov/gds-sso) to standardise the
integration for most of our core applications.

We have made a deliberate decision not to track each and every version of the
evolving specification. This is primarily a pragmatic decision: the
specification is changing frequently in minor ways and the task of tracking
and managing that would be substantial. We do not believe that tracking those
changes would make a substantial difference to the security of our applications.
When the specification reaches a formal RFC state we will revisit this decision
and make any appropriate adjustments.

## Roles

Our implementation of the four roles defined in OAuth are:

### Resource owner

The resource owner role is currently divided in two:

* The end-user is the owner of the credentials
* A GDS administrator will be the owner of permissions associated with the
account, which are the resource to be shared with the client.

### Resource server

The resource server is the sign-on-o-tron application, where the resource
is a set of us user permissions.

### Client

The clients are the various admin and editorial applications.

### Authorization server

The sign-on-o-tron application.

## Client Registration

Client credentials are created by developers using a standard script. Those
credentials are included in applications through a configuration file that
is not shared publicly.

For the purposes of section 3.1 of the spec the client type is considered to
be *confidential* as the credentials can be maintained securely. Our clients
are *web applications*.

Following section 3.1.1 of the specification they consist of a *client_id* and
a *client_secret* and should be sent in the body of the HTTP request. eg.

    POST /token HTTP/1.1

    Host: server.example.com
    Content-Type: application/x-www-form-urlencoded;charset=UTF-8

    grant_type=access_token&client_id=s6BhdRkqt3&client_secret=7Fjfp0ZBr1KtDRbnfVdmIw

*Since this client authentication method involves a password, the authorization
server MUST protect any endpoint utilizing it against brute force attacks.*

## Obtaining Authorization

### End-user requests

For end-user requests, we use the Authorization Code grant type and follow the
standard Authorization Code Flow as illustrated in section 5.1 of the
specification.

The resource server will obtain an access code from the authorization server,
and then issue an HTTPS redirect to the authorization server to allow it to
authenticate the client.

The authorization server will then return the client to the resource server
and provide an access token for validation.

Access tokens are issued with an expiry of 7200 seconds (2 hours) after which
the refresh token process will need to be followed. (for section 5.2, the
expires_in value will always be sent and end-user facing clients MUST be
able to interpret it and follow the refresh process)

### API requests

For API requests, we use the Implicit grant type:

API clients will be issued an access token in advance generated through a
regular process. Those clients send that access token to the resource owner
as a Bearer token (see specification section 8.1), and the resource owner
then validates that token against the authorization server.

## Access Tokens

We don't make use of access token scopes.

We do require use of the 'state' parameter in authorization requests to
mitigate the risk of cross-site request forgery.

##  Overlaying Permissions

While OAuth itself is an authorization protocol we are using it to authorize
an application’s permission to retrieve details of a given user. The
sign-on-o-tron application will return details of a user and the client
applications are responsible for interpreting those to provide authorization
*within* that application.

A request to /user.json (used to retrieve user permissions and authenticated
and resolved to a specific user by passing the access_token in the request)
will return something a JSON response such as:

    {
      "user": {
        "uid": "fakeuid",
        "name": "Fake User",
        "email": "fake.user@digital.cabinet-office.gov.uk",
        "permissions": {
          "Need-o-Tron": ["signin","admin"],
          "Publisher": ["signin"],
          "Whitehall": ["signin"],
          "Panopticon": ["signin"],
          "Imminence": ["signin"],
          "Migratorator": ["signin"]
        }
      }
    }

While this is the full set of permissions a given app will only actually see
its own permissions, so a request from Publisher would return:

    {
      "user": {
        "uid": "fakeuid",
        "name": "Fake User",
        "email": "fake.user@digital.cabinet-office.gov.uk",
        "permissions": ["signin"],
      }
    }

In addition, the authorization server employs a mechanism for informing an
application that a user’s status has changed (eg. their permissions have
changed or their account has been suspended).

Where permissions have changed the authorization server will send each
application an HTTP PUT to /users/{user.uid} with the full user object in
JSON (as above). The application MUST then update its record of that user's
permissions and change its behaviour accordingly.

Where a user has been suspended sign-on-o-tron will send each application
an HTTP POST to /users/{user.uid}/reauth. The application MUST then invalidate
the user’s current session and redirect them to the authorization server.

The gds-sso library provides utilities to help GDS’ ruby applications manage
these processes consistently.

## Security

### Transport-level security

The GOV.UK Single-Sign-On tools are intended for use exclusively over HTTPS
and decisions about use of the protocol have been made on that basis. In
addition, all related applications will be operating solely over HTTPS.

### Credential protection

Access and Refresh Tokens, Client IDs and Client Secrets are all generated
by Doorkeeper using the ruby [SecureRandom module](http://rubydoc.info/stdlib/securerandom/1.9.2/SecureRandom).
The module is used to generate a random hex string with a random length of 32.

The relevant SecureRandom code can be found at:
[https://github.com/ruby/ruby/blob/trunk/lib/securerandom.rb#L59](https://github.com/ruby/ruby/blob/trunk/lib/securerandom.rb#L59)

Where OpenSSL is available it is used by the SecureRandom module, seeded with
the current time and the current process’ pid:

    @pid = 0 if !defined?(@pid)
    pid = $$
    if @pid != pid
      now = Time.now
      ary = [now.to_i, now.nsec, @pid, pid]
      OpenSSL::Random.seed(ary.to_s)
      @pid = pid
    end
    return OpenSSL::Random.random_bytes(n)

Where OpenSSL is not available SecureRandom falls back to /dev/urandom. GDS
servers are configured with OpenSSL available.
