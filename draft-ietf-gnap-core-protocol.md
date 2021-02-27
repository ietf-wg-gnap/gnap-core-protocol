---
title: 'Grant Negotiation and Authorization Protocol'
docname: draft-ietf-gnap-core-protocol-latest
category: std

ipr: trust200902
area: Security
workgroup: GNAP
keyword: Internet-Draft

stand_alone: yes
pi: [toc, tocindent, sortrefs, symrefs, strict, compact, comments, inline, docmapping]

author:
  - ins: J. Richer
    name: Justin Richer
    organization: Bespoke Engineering
    email: ietf@justin.richer.org
    uri: https://bspk.io/
    role: editor

  - ins: A. Parecki
    name: Aaron Parecki
    email: aaron@parecki.com
    organization: Okta
    uri: https://aaronparecki.com

  - ins: F. Imbault
    name: Fabien Imbault
    organization: acert.io
    email: fabien.imbault@acert.io
    uri: https://acert.io/

normative:
    BCP195:
       target: 'https://www.rfc-editor.org/info/bcp195'
       title: Recommendations for Secure Use of Transport Layer Security (TLS) and Datagram Transport Layer Security (DTLS)
       date: May 2015
       author:
         - 
           ins: Y. Sheffer
         - 
           ins: R. Holz
         -
           ins: P. Saint-Andre
    RFC2119:
    RFC3230:
    RFC5646:
    RFC7468:
    RFC7515:
    RFC7517:
    RFC6749:
    RFC6750:
    RFC7797:
    RFC8174:
    RFC8259:
    RFC8705:
    RFC8693:
    I-D.ietf-httpbis-message-signatures:
    I-D.ietf-oauth-signed-http-request:
    I-D.ietf-oauth-dpop:
    I-D.ietf-secevent-subject-identifiers:
    OIDC:
      title: OpenID Connect Core 1.0 incorporating errata set 1
      target: https://openiD.net/specs/openiD-connect-core-1_0.html
      date: November 8, 2014
      author:
        -
          ins: N. Sakimura
        -
          ins: J. Bradley
        -
          ins: M. Jones
        -
          ins: B. de Medeiros
        -
          ins: C. Mortimore

--- abstract

GNAP defines a mechanism for delegating authorization to a
piece of software, and conveying that delegation to the software. This
delegation can include access to a set of APIs as well as information
passed directly to the software.


--- middle

# Introduction

This protocol allows a piece of software, the client instance, to request delegated
authorization to resource servers and to request direct information. This delegation is
facilitated by an authorization server usually on
behalf of a resource owner. The end-user operating the software may interact
with the authorization server to authenticate, provide consent, and
authorize the request.

The process by which the delegation happens is known as a grant, and
GNAP allows for the negotiation of the grant process
over time by multiple parties acting in distinct roles. 

This protocol solves many of the same use cases as OAuth 2.0 {{RFC6749}},
OpenID Connect {{OIDC}}, and the family of protocols that have grown up
around that ecosystem. However, GNAP is not an extension of OAuth 2.0
and is not intended to be directly compatible with OAuth 2.0. GNAP seeks to
provide functionality and solve use cases that OAuth 2.0 cannot easily
or cleanly address. Even so, GNAP and OAuth 2.0 will exist in parallel 
for many deployments, and considerations have been taken to facilitate
the mapping and transition from legacy systems to GNAP. Some examples
of these can be found in {{example-oauth2}}. 

## Terminology

{::boilerplate bcp14}

## Roles

The parties in GNAP perform actions under different roles. 
Roles are defined by the actions taken and the expectations leveraged
on the role by the overall protocol. 

Authorization Server (AS)
: server that grants delegated privileges to a particular instance of client software in the form of an access token and other information (such as subject information). 

Client
: application operated by an end-user that consumes resources from one or several RSs, possibly requiring access privileges from one or several ASs. 

    Example: a client can be a mobile application, a web application, etc.

    Note: this specification differentiates between a specific instance (the client instance, identified by its unique key) and the software running the instance (the client software). For some kinds of client software, there could be many instances of that software, each instance with a different key.

Resource Server (RS)
: server that provides operations on protected resources, where operations require a valid access token issued by an AS. 

Resource Owner (RO)
: subject entity that may grant or deny operations on resources it has authority upon.

    Note: the act of granting or denying an operation may be manual (i.e. through an interaction with a physical person) or automatic (i.e. through predefined organizational rules).

End-user 
: natural person that operates a client instance.

    Note: that natural person may or may not be the same entity as the RO. 

The design of GNAP does not assume any one deployment architecture,
but instead attempts to define roles that can be fulfilled in a number
of different ways for different use cases. As long as a given role fulfills
all of its obligations and behaviors as defined by the protocol, GNAP does
not make additional requirements on its structure or setup.

Multiple roles can be fulfilled by the same party, and a given party
can switch roles in different instances of the protocol. For example,
the RO and end-user in many instances are the same person, where a user is
authorizing the client instance to act on their own behalf at the RS. In this case,
one party fulfills both of the RO and end-user roles, but the roles themselves
are still defined separately from each other to allow for other
use cases where they are fulfilled by different parties.

For another example,
in some complex scenarios, an RS receiving requests from one client instance can act as
a client instance for a downstream secondary RS in order to fulfill the 
original request. In this case, one piece of software is both an 
RS and a client instance from different perspectives, and it fulfills these 
roles separately as far as the overall protocol is concerned.

A single role need not be deployed as a monolithic service. For example, 
A client instance could have components that are installed on the end-user's device as 
well as a back-end system that it communicates with. If both of these
components participate in the delegation protocol, they are both considered
part of the client instance. If there are several copies of the client software
that run separately but all share the same key material, such as a
deployed cluster, then this cluster is considered a single client instance.

For another example, an AS could likewise be built out of many constituent
components in a distributed architecture. The component that the client instance
calls directly could be different from the component that the the
RO interacts with to drive consent, since API calls and user interaction
have different security considerations in many environments. Furthermore,
the AS could need to collect identity claims about the RO from one system
that deals with user attributes while generating access tokens at
another system that deals with security rights. From the perspective of
GNAP, all of these are pieces of the AS and together fulfill the
role of the AS as defined by the protocol.

## Elements {#elements}

In addition to the roles above, the protocol also involves several 
elements that are acted upon by the roles throughout the process.

Attribute
: characteristics related to a subject.

Access Token
: a data artifact representing a set of rights and/or attributes.

    Note: an access token can be first issued to an client instance (requiring authorization by the RO) and subsequently rotated.

Grant
: (verb): to permit an instance of client software to receive some attributes at a specific time and valid for a specific duration and/or to exercise some set of delegated rights to access a protected resource (noun): the act of granting. 

Privilege
: right or attribute associated with a subject.

    Note: the RO defines and maintains the rights and attributes associated to the protected resource, and might temporarily delegate some set of those privileges to an end-user. This process is refered to as privilege delegation. 

Protected Resource
: protected API (Application Programming Interface) served by an RS and that can be accessed by a client, if and only if a valid access token is provided.

    Note: to avoid complex sentences, the specification document may simply refer to resource instead of protected resource.   

Right
: ability given to a subject to perform a given operation on a resource under the control of an RS.

Subject
: person, organization or device.

Subject Information
: statement asserted locally by an AS about a subject.

## Sequences {#sequence}

GNAP can be used in a variety of ways to allow the core
delegation process to take place. Many portions of this process are
conditionally present depending on the context of the deployments,
and not every step in this overview will happen in all circumstances.

Note that a connection between roles in this process does not necessarily
indicate that a specific protocol message is sent across the wire
between the components fulfilling the roles in question, or that a 
particular step is required every time. For example, for a client instance interested
in only getting subject information directly, and not calling an RS,
all steps involving the RS below do not apply. 

In some circumstances,
the information needed at a given stage is communicated out of band
or is preconfigured between the components or entities performing
the roles. For example, one entity can fulfil multiple roles, and so
explicit communication between the roles is not necessary within the
protocol flow.

~~~
        +------------+             +------------+
        | End-user   | ~ ~ ~ ~ ~ ~ |  Resource  |
        |            |             | Owner (RO) |
        +------------+             +------------+
            +                            +      
            +                            +      
           (A)                          (B)       
            +                            +        
            +                            +         
        +--------+                       +       +------------+
        | Client |--------------(1)------+------>|  Resource  |
        |Instance|                       +       |   Server   |
        |        |       +---------------+       |    (RS)    |
        |        |--(2)->| Authorization |       |            |
        |        |<-(3)--|     Server    |       |            |
        |        |       |      (AS)     |       |            |
        |        |--(4)->|               |       |            |
        |        |<-(5)--|               |       |            |
        |        |--------------(6)------------->|            |
        |        |       |               |<~(7)~~|            |
        |        |<-------------(8)------------->|            |
        |        |--(9)->|               |       |            |
        |        |<-(10)-|               |       |            |
        |        |--------------(11)------------>|            |
        |        |       |               |<~(12)~|            |
        |        |-(13)->|               |       |            |
        |        |       |               |       |            |
        +--------+       +---------------+       +------------+
    
    Legend
    + + + indicates a possible interaction with a human
    ----- indicates an interaction between protocol roles
    ~ ~ ~ indicates a potential equivalence or out-of-band communication between roles
~~~

- (A) The end-user interacts with the client instance to indicate a need for resources on
    behalf of the RO. This could identify the RS the client instance needs to call,
    the resources needed, or the RO that is needed to approve the 
    request. Note that the RO and end-user are often
    the same entity in practice.
    
- (1) The client instance [attempts to call the RS](#rs-request-without-token) to determine 
    what access is needed.
    The RS informs the client instance that access can be granted through the AS. Note that
    for most situations, the client instance already knows which AS to talk to and which
    kinds of access it needs.

- (2) The client instance [requests access at the AS](#request).

- (3) The AS processes the request and determines what is needed to fulfill
    the request. The AS sends its [response to the client instance](#response).

- (B) If interaction is required, the 
    AS [interacts with the RO](#user-interaction) to gather authorization.
    The interactive component of the AS can function
    using a variety of possible mechanisms including web page
    redirects, applications, challenge/response protocols, or 
    other methods. The RO approves the request for the client instance
    being operated by the end-user. Note that the RO and end-user are often
    the same entity in practice.

- (4) The client instance [continues the grant at the AS](#continue-request).

- (5) If the AS determines that access can be granted, it returns a 
    [response to the client instance](#response) including an [access token](#response-token) for 
    calling the RS and any [directly returned information](#response-subject) about the RO.

- (6) The client instance [uses the access token](#use-access-token) to call the RS.

- (7) The RS determines if the token is sufficient for the request by
    examining the token, potentially [calling the AS](#introspection). Note that
    the RS could also examine the token directly, call an internal data store,
    execute a policy engine request, or any number of alternative methods for
    validating the token and its fitness for the request.
    
- (8) The client instance [calls the RS](#use-access-token) using the access token
    until the RS or client instance determine that the token is no longer valid.
    
- (9) When the token no longer works, the client instance fetches an 
    [updated access token](#rotate-access-token) based on the
    rights granted in (5).
    
- (10) The AS issues a [new access token](#response-token) to the client instance.

- (11) The client instance [uses the new access token](#use-access-token) to call the RS.

- (12) The RS determines if the new token is sufficient for the request by
    examining the token, potentially [calling the AS](#introspection).

- (13) The client instance [disposes of the token](#revoke-access-token) once the client instance
    has completed its access of the RS and no longer needs the token.

The following sections and {{examples}} contain specific guidance on how to use
GNAP in different situations and deployments.

### Redirect-based Interaction {#sequence-redirect}

In this example flow, the client instance is a web application that wants access to resources on behalf
of the current user, who acts as both the end-user and the resource
owner (RO). Since the client instance is capable of directing the user to an arbitrary URL and 
receiving responses from the user's browser, interaction here is handled through
front-channel redirects using the user's browser. The client instance uses a persistent session
with the user to ensure the same user that is starting the interaction is the user 
that returns from the interaction.

~~~
    +--------+                                  +--------+         +------+
    | Client |                                  |   AS   |         | User |
    |Instance|                                  |        |         |      |
    |        |< (1) + Start Session + + + + + + + + + + + + + + + +|      |
    |        |                                  |        |         |      |
    |        |--(2)--- Request Access --------->|        |         |      |
    |        |                                  |        |         |      |
    |        |<-(3)-- Interaction Needed -------|        |         |      |
    |        |                                  |        |         |      |
    |        |+ (4) + Redirect for Interaction + + + + + + + + + > |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (5) +>|      |
    |        |                                  |        |  AuthN  |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (6) +>|      |
    |        |                                  |        |  AuthZ  |      |
    |        |                                  |        |         |      |
    |        |< (7) + Redirect for Continuation + + + + + + + + + +|      |
    |        |                                  |        |         +------+
    |        |--(8)--- Continue Request ------->|        |
    |        |                                  |        |
    |        |<-(9)----- Grant Access ----------|        |
    |        |                                  |        |
    +--------+                                  +--------+
~~~

1. The client instance establishes a verifiable session to the user, in the role of the end-user. 

2. The client instance [requests access to the resource](#request). The client instance indicates that
    it can [redirect to an arbitrary URL](#request-interact-redirect) and
    [receive a redirect from the browser](#request-interact-callback-redirect). The client instance
    stores verification information for its redirect in the session created
    in (1).

3. The AS determines that interaction is needed and [responds](#response) with
    a [URL to send the user to](#response-interact-redirect) and
    [information needed to verify the redirect](#response-interact-callback) in (7).
    The AS also includes information the client instance will need to 
    [continue the request](#response-continue) in (8). The AS associates this
    continuation information with an ongoing request that will be referenced in (4), (6), and (8).

4. The client instance stores the verification and continuation information from (3) in the session from (1). The client instance
    then [redirects the user to the URL](#interaction-redirect) given by the AS in (3).
    The user's browser loads the interaction redirect URL. The AS loads the pending
    request based on the incoming URL generated in (3).

5. The user authenticates at the AS, taking on the role of the RO.

6. As the RO, the user authorizes the pending request from the client instance. 

7. When the AS is done interacting with the user, the AS 
    [redirects the user back](#interaction-callback) to the
    client instance using the redirect URL provided in (2). The redirect URL is augmented with
    an interaction reference that the AS associates with the ongoing 
    request created in (2) and referenced in (4). The redirect URL is also
    augmented with a hash of the security information provided
    in (2) and (3). The client instance loads the verification information from (2) and (3) from 
    the session created in (1). The client instance [calculates a hash](#interaction-hash)
    based on this information and continues only if the hash validates.
    Note that the client instance needs to ensure that the parameters for the incoming
    request match those that it is expecting from the session created
    in (1). The client instance also needs to be prepared for the end-user never being returned
    to the client instance and handle timeouts appropriately.
    
8. The client instance loads the continuation information from (3) and sends the 
    interaction reference from (7) in a request to
    [continue the request](#continue-after-interaction). The AS
    validates the interaction reference ensuring that the reference
    is associated with the request being continued. 
    
9. If the request has been authorized, the AS grants access to the information
    in the form of [access tokens](#response-token) and
    [direct subject information](#response-subject) to the client instance.

An example set of protocol messages for this method can be found in {{example-auth-code}}.

### User-code Interaction {#sequence-user-code}

In this example flow, the client instance is a device that is capable of presenting a short,
human-readable code to the user and directing the user to enter that code at
a known URL. The client instance is not capable of presenting an arbitrary URL to the user, 
nor is it capable of accepting incoming HTTP requests from the user's browser.
The client instance polls the AS while it is waiting for the RO to authorize the request.
The user's interaction is assumed to occur on a secondary device. In this example
it is assumed that the user is both the end-user and RO, though the user is not assumed
to be interacting with the client instance through the same web browser used for interaction at
the AS.

~~~
    +--------+                                  +--------+         +------+
    | Client |                                  |   AS   |         | User |
    |Instance|--(1)--- Request Access --------->|        |         |      |
    |        |                                  |        |         |      |
    |        |<-(2)-- Interaction Needed -------|        |         |      |
    |        |                                  |        |         |      |
    |        |+ (3) + + Display User Code + + + + + + + + + + + + >|      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (4) + |      |
    |        |                                  |        |Open URI |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (5) +>|      |
    |        |                                  |        |  AuthN  |      |
    |        |--(9)--- Continue Request (A) --->|        |         |      |
    |        |                                  |        |<+ (6) +>|      |
    |        |<-(10)- Not Yet Granted (Wait) ---|        |  Code   |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (7) +>|      |
    |        |                                  |        |  AuthZ  |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (8) +>|      |
    |        |                                  |        |Completed|      |
    |        |                                  |        |         |      |
    |        |--(11)-- Continue Request (B) --->|        |         +------+
    |        |                                  |        |
    |        |<-(12)----- Grant Access ---------|        |
    |        |                                  |        |
    +--------+                                  +--------+
~~~

1. The client instance [requests access to the resource](#request). The client instance indicates that
    it can [display a user code](#request-interact-usercode).

2. The AS determines that interaction is needed and [responds](#response) with
    a [user code to communicate to the user](#response-interact-usercode). This
    could optionally include a URL to direct the user to, but this URL should
    be static and so could be configured in the client instance's documentation.
    The AS also includes information the client instance will need to 
    [continue the request](#response-continue) in (8) and (10). The AS associates this
    continuation information with an ongoing request that will be referenced in (4), (6), (8), and (10).

3. The client instance stores the continuation information from (2) for use in (8) and (10). The client instance
    then [communicates the code to the user](#interaction-redirect) given by the AS in (2).

4. The user's directs their browser to the user code URL. This URL is stable and
    can be communicated via the client software's documentation, the AS documentation, or
    the client software itself. Since it is assumed that the RO will interact
    with the AS through a secondary device, the client instance does not provide a mechanism to
    launch the RO's browser at this URL.
    
5. The end-user authenticates at the AS, taking on the role of the RO.

6.  The RO enters the code communicated in (3) to the AS. The AS validates this code
    against a current request in process.

7. As the RO, the user authorizes the pending request from the client instance. 

8. When the AS is done interacting with the user, the AS 
    indicates to the RO that the request has been completed.
    
9. Meanwhile, the client instance loads the continuation information stored at (3) and 
    [continues the request](#continue-request). The AS determines which
    ongoing access request is referenced here and checks its state.
    
10. If the access request has not yet been authorized by the RO in (6),
    the AS responds to the client instance to [continue the request](#response-continue)
    at a future time through additional polled continuation requests. This response can include
    updated continuation information as well as information regarding how long the
    client instance should wait before calling again. The client instance replaces its stored
    continuation information from the previous response (2).
    Note that the AS may need to determine that the RO has not approved
    the request in a sufficient amount of time and return an appropriate
    error to the client instance.

11. The client instance continues to [poll the AS](#continue-poll) with the new
    continuation information in (9).
    
12. If the request has been authorized, the AS grants access to the information
    in the form of [access tokens](#response-token) and
    [direct subject information](#response-subject) to the client instance.

An example set of protocol messages for this method can be found in {{example-device}}.

### Asynchronous Authorization {#sequence-async}

In this example flow, the end-user and RO roles are fulfilled by different parties, and
the RO does not interact with the client instance. The AS reaches out asynchronously to the RO 
during the request process to gather the RO's authorization for the client instance's request. 
The client instance polls the AS while it is waiting for the RO to authorize the request.


~~~
    +--------+                                  +--------+         +------+
    | Client |                                  |   AS   |         |  RO  |
    |Instance|--(1)--- Request Access --------->|        |         |      |
    |        |                                  |        |         |      |
    |        |<-(2)-- Not Yet Granted (Wait) ---|        |         |      |
    |        |                                  |        |<+ (3) +>|      |
    |        |                                  |        |  AuthN  |      |
    |        |--(6)--- Continue Request (A) --->|        |         |      |
    |        |                                  |        |<+ (4) +>|      |
    |        |<-(7)-- Not Yet Granted (Wait) ---|        |  AuthZ  |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (5) +>|      |
    |        |                                  |        |Completed|      |
    |        |                                  |        |         |      |
    |        |--(8)--- Continue Request (B) --->|        |         +------+
    |        |                                  |        |
    |        |<-(9)------ Grant Access ---------|        |
    |        |                                  |        |
    +--------+                                  +--------+
~~~

1. The client instance [requests access to the resource](#request). The client instance does not
    send any interactions modes to the server, indicating that
    it does not expect to interact with the RO. The client instance can also signal
    which RO it requires authorization from, if known, by using the
    [user request section](#request-user). 

2. The AS determines that interaction is needed, but the client instance cannot interact
    with the RO. The AS [responds](#response) with the information the client instance 
    will need to [continue the request](#response-continue) in (6) and (8), including
    a signal that the client instance should wait before checking the status of the request again.
    The AS associates this continuation information with an ongoing request that will be 
    referenced in (3), (4), (5), (6), and (8).

3. The AS determines which RO to contact based on the request in (1), through a
    combination of the [user request](#request-user), the 
    [resources request](#request-token), and other policy information. The AS
    contacts the RO and authenticates them.

4. The RO authorizes the pending request from the client instance.

5. When the AS is done interacting with the RO, the AS 
    indicates to the RO that the request has been completed.
    
6. Meanwhile, the client instance loads the continuation information stored at (3) and 
    [continues the request](#continue-request). The AS determines which
    ongoing access request is referenced here and checks its state.
    
7. If the access request has not yet been authorized by the RO in (6),
    the AS responds to the client instance to [continue the request](#response-continue)
    at a future time through additional polling. This response can include
    refreshed credentials as well as information regarding how long the
    client instance should wait before calling again. The client instance replaces its stored
    continuation information from the previous response (2).
    Note that the AS may need to determine that the RO has not approved
    the request in a sufficient amount of time and return an appropriate
    error to the client instance.

8. The client instance continues to [poll the AS](#continue-poll) with the new 
    continuation information from (7).
    
9. If the request has been authorized, the AS grants access to the information
    in the form of [access tokens](#response-token) and
    [direct subject information](#response-subject) to the client instance.

An example set of protocol messages for this method can be found in {{example-async}}.

### Software-only Authorization {#sequence-no-user}

In this example flow, the AS policy allows the client instance to make a call on its own behalf,
without the need for a RO to be involved at runtime to approve the decision.
Since there is no explicit RO, the client instance does not interact with an RO.

~~~
    +--------+                                  +--------+
    | Client |                                  |   AS   |
    |Instance|--(1)--- Request Access --------->|        |
    |        |                                  |        |
    |        |<-(2)---- Grant Access -----------|        |
    |        |                                  |        |
    +--------+                                  +--------+
~~~

1. The client instance [requests access to the resource](#request). The client instance does not
    send any interactions modes to the server.

2. The AS determines that the request is been authorized, 
    the AS grants access to the information
    in the form of [access tokens](#response-token) and
    [direct subject information](#response-subject) to the client instance.

An example set of protocol messages for this method can be found in {{example-no-user}}.

### Refreshing an Expired Access Token {#sequence-refresh}

In this example flow, the client instance receives an access token to access a resource server through
some valid GNAP process. The client instance uses that token at the RS for some time, but eventually
the access token expires. The client instance then gets a new access token by rotating the
expired access token at the AS using the token's management URL.

~~~
    +--------+                                          +--------+  
    | Client |                                          |   AS   |
    |Instance|--(1)--- Request Access ----------------->|        |
    |        |                                          |        |
    |        |<-(2)--- Grant Access --------------------|        |
    |        |                                          |        |
    |        |                             +--------+   |        |
    |        |--(3)--- Access Resource --->|   RS   |   |        | 
    |        |                             |        |   |        | 
    |        |<-(4)--- Error Response -----|        |   |        |
    |        |                             +--------+   |        |
    |        |                                          |        |
    |        |--(5)--- Rotate Token ------------------->|        |
    |        |                                          |        |
    |        |<-(6)--- Rotated Token -------------------|        |
    |        |                                          |        |
    +--------+                                          +--------+
~~~

1. The client instance [requests access to the resource](#request).

2. The AS [grants access to the resource](#response) with an
    [access token](#response-token) usable at the RS. The access token
    response includes a token management URI.
    
3. The client instance [presents the token](#use-access-token) to the RS. The RS 
    validates the token and returns an appropriate response for the
    API.
    
4. When the access token is expired, the RS responds to the client instance with
    an error.
    
5. The client instance calls the token management URI returned in (2) to
    [rotate the access token](#rotate-access-token). The client instance
    presents the access token as well as the appropriate key.

6. The AS validates the rotation request including the signature
    and keys presented in (5) and returns a 
    [new access token](#response-token-single). The response includes
    a new access token and can also include updated token management 
    information, which the client instance will store in place of the values 
    returned in (2).
   
# Requesting Access {#request}

To start a request, the client instance sends [JSON](#RFC8259) document with an object as its root. Each
member of the request object represents a different aspect of the
client instance's request. Each field is described in detail in a section below.

access_token (object / array of objects)
: Describes the rights and properties associated with the requested access token. {{request-token}}

subject (object)
: Describes the information about the RO that the client instance is requesting to be returned
    directly in the response from the AS. {{request-subject}}

client (object / string)
: Describes the client instance that is making this request, including 
    the key that the client instance will use to protect this request and any continuation
    requests at the AS and any user-facing information about the client instance used in 
    interactions at the AS. {{request-client}}

user (object / string)
: Identifies the end-user to the AS in a manner that the AS can verify, either directly or
    by interacting with the end-user to determine their status as the RO. {{request-user}}

interact (object)
: Describes the modes that the client instance has for allowing the RO to interact with the
    AS and modes for the client instance to receive updates when interaction is complete. {{request-interact}}

capabilities (array of strings)
: Identifies named extension capabilities that the client instance can use, signaling to the AS
    which extensions it can use. {{request-capabilities}}

existing_grant (string)
: Identifies a previously-existing grant that the client instance is extending with this request. {{request-existing}}

Additional members of this request object can be defined by extensions to this protocol
as described in {{request-extending}}

A non-normative example of a grant request is below:

~~~
{
    "access_token": {
        "access": [
            {
                "type": "photo-api",
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            },
            "dolphin-metadata"
        ]
    },
    "client": {
      "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
      },
      "key": {
        "proof": "jwsd",
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeL...."
        }
      }
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return/123455",
            "nonce": "LKLTI25DK82FX4T4QFZC"
        }
    },
    "capabilities": ["ext1", "ext2"],
    "subject": {
        "sub_ids": ["iss_sub", "email"],
        "assertions": ["id_token"]
    }
}
~~~



The request MUST be sent as a JSON object in the body of the HTTP
POST request with Content-Type `application/json`,
unless otherwise specified by the signature mechanism.

## Requesting Access to Resources {#request-token}

If the client instance is requesting one or more access tokens for the
purpose of accessing an API, the client instance MUST include an `access_token`
field. This field MUST be an object (for a [single access token](#request-token-single)) or
an array of these objects (for [multiple access tokens](#request-token-multiple)), 
as described in the following sections.

### Requesting a Single Access Token {#request-token-single}

To request a single access token, the client instance sends an `acccess_token` object
composed of the following fields.

access (array of objects/strings)
: Describes the rights that the client instance is requesting for one or more access tokens to be
    used at RS's. This field is REQUIRED. {{resource-access-rights}}

label (string)
: A unique name chosen by the client instance to refer to the resulting access token. The value of this
    field is opaque to the AS.  If this field
    is included in the request, the AS MUST include the same label in the [token response](#response-token).
    This field is REQUIRED if used as part of a [multiple access token request](#request-token-multiple),
    and is OPTIONAL otherwise.

flags (array of strings)
: A set of flags that indicate desired attributes or behavior to be attached to the access token by the
    AS. This field is OPTIONAL.

The values of the `flags` field defined by this specification are as follows:

bearer
: If this flag is included, the access token being requested is a bearer token.
    If this flag is omitted, the access token is bound to the key used
    by the client instance in this request, or the key's most recent rotation. 
    Methods for presenting bound and bearer access tokens are described
    in {{use-access-token}}.
    \[\[ [See issue #38](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/38) \]\]

split
: If this flag is included, the client instance is capable of 
    receiving a different number of tokens than specified in the
    [token request](#request-token), including 
    receiving [multiple access tokens](#response-token-multiple)
    in response to any [single token request](#request-token-single) or a
    different number of access tokens than requested in a [multiple access token request](#request-token-multiple).
    The `label` fields of the returned additional tokens are chosen by the AS. 
    The client instance MUST be able to tell from the token response where and 
    how it can use each of the access tokens. 
    \[\[ [See issue #37](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/37) \]\]

Flag values MUST NOT be included more than once.

Additional flags can be defined by extensions using [a registry TBD](#IANA).


In the following example, the client instance is requesting access to a complex resource
described by a pair of access request object. 

~~~
"access_token": {
    "access": [
        {
            "type": "photo-api",
            "actions": [
                "read",
                "write",
                "delete"
            ],
            "locations": [
                "https://server.example.net/",
                "https://resource.local/other"
            ],
            "datatypes": [
                "metadata",
                "images"
            ]
        },
        {
            "type": "walrus-access",
            "actions": [
                "foo",
                "bar"
            ],
            "locations": [
                "https://resource.other/"
            ],
            "datatypes": [
                "data",
                "pictures",
                "walrus whiskers"
            ]
        }
    ],
    "label": "token1-23",
    "flags": [ "split" ]
}
~~~

If access is approved, the resulting access token is valid for the described resource 
and is bound to the client instance's key (or its most recent rotation). The token 
is labeled "token1-23" and could be split into multiple access tokens by the AS, if the
AS chooses. The token response structure is described in {{response-token-single}}.

### Requesting Multiple Access Tokens {#request-token-multiple}

To request multiple access tokens to be returned in a single response, the
client instance sends an array of objects as the value of the `access_token`
parameter. Each object MUST conform to the request format for a single
access token request, as specified in 
[requesting a single access token](#request-token-single).
Additionally, each object in the array MUST include the `label` field, and
all values of these fields MUST be unique within the request. If the
client instance does not include a `label` value for any entry in the
array, or the values of the `label` field are not unique within the array,
the AS MUST return an error.

The following non-normative example shows a request for two
separate access tokens, `token1` and `token2`.

~~~
"access_token": [
    {
        "label": "token1",
        "access": [
            {
                "type": "photo-api",
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            },
            "dolphin-metadata"
        ]
    },
    {
        "label": "token2",
        "access": [
            {
                "type": "walrus-access",
                "actions": [
                    "foo",
                    "bar"
                ],
                "locations": [
                    "https://resource.other/"
                ],
                "datatypes": [
                    "data",
                    "pictures",
                    "walrus whiskers"
                ]
            }
        ],
        "flags": [ "bearer" ]
    }
]
~~~

All approved access requests are returned in the 
[multiple access token response](#response-token-multiple) structure using
the values of the `label` fields in the request.

## Requesting Subject Information {#request-subject}

If the client instance is requesting information about the RO from
the AS, it sends a `subject` field as a JSON object. This object MAY
contain the following fields (or additional fields defined in 
[a registry TBD](#IANA)).

sub_ids (array of strings)
: An array of subject identifier subject types
            requested for the RO, as defined by {{I-D.ietf-secevent-subject-identifiers}}.

assertions (array of strings)
: An array of requested assertion formats. Possible values include
    `id_token` for an {{OIDC}} ID Token and `saml2` for a SAML 2 assertion. Additional
    assertion values are defined by [a registry TBD](#IANA).
    \[\[ [See issue #41](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/41) \]\]

~~~
"subject": {
   "sub_ids": [ "iss_sub", "email" ],
   "assertions": [ "id_token", "saml2" ]
}
~~~

The AS can determine the RO's identity and permission for releasing
this information through [interaction with the RO](#user-interaction),
AS policies, or [assertions presented by the client instance](#request-user). If
this is determined positively, the AS MAY [return the RO's information in its response](#response-subject)
as requested. 

Subject identifiers requested by the client instance serve only to identify 
the RO in the context of the AS and can't be used as communication
channels by the client instance, as discussed in {{response-subject}}.

The AS SHOULD NOT re-use subject identifiers for multiple different ROs.

\[\[ [See issue #42](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/42) \]\]

Note: the "sub_ids" and "assertions" request fields are independent of
each other, and a returned assertion MAY omit a requested subject
identifier. 

\[\[ [See issue #43](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/43) \]\]

## Identifying the Client Instance {#request-client}

When sending a non-continuation request to the AS, the client instance MUST identify
itself by including the `client` field of the request and by signing the
request as described in {{binding-keys}}. Note that for a 
[continuation request](#continue-request), the client instance is identified by its
association with the request being continued and so this field is
not sent under those circumstances.

When client instance information is sent
by value, the `client` field of the request consists of a JSON
object with the following fields.

key (object / string)
: The public key of the client instance to be used in this request as 
    described in {{key-format}} or a reference to a key as
    described in {{key-reference}}. This field is REQUIRED.

class_id (string)
: An identifier string that the AS can use to identify the
    client software comprising this client instance. The contents
    and format of this field are up to the AS. This field
    is OPTIONAL.

display (object)
: An object containing additional information that the AS 
    MAY display to the RO during interaction, authorization,
    and management. This field is OPTIONAL.

~~~
"client": {
    "key": {
        "proof": "httpsig",
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_JtffXyaSx8xY..."
        },
        "cert": "MIIEHDCCAwSgAwIBAgIBATANBgkqhkiG9w0BAQsFA..."
    },
    "class_id": "web-server-1234",
    "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
    }
}
~~~

Additional fields are defined in [a registry TBD](#IANA).

The client instance MUST prove possession of any presented key by the `proof` mechanism
associated with the key in the request.  Proof types
are defined in [a registry TBD](#IANA) and an initial set of methods
is described in {{binding-keys}}. 

Note that the AS MAY know the client instance's public key ahead of time, and
the AS MAY apply different policies to the request depending on what
has been registered against that key. 
If the same public key is sent by value on subsequent access requests, the AS SHOULD
treat these requests as coming from the same client instance for purposes
of identification, authentication, and policy application.
If the AS does not know the client instance's public key ahead of time, the AS
MAY accept or reject the request based on AS policy, attestations
within the `client` request, and other mechanisms.

\[\[ [See issue #44](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/44) \]\]

### Identifying the Client Instance by Reference {#request-instance}

If the client instance has an instance identifier that the AS can use to determine
appropriate key information, the client instance can send this value in the `instance_id`
field. The instance identifier MAY be assigned to a client instance at runtime
through the {{response-dynamic-handles}} or MAY be obtained in another fashion,
such as a static registration process at the AS.

instance_id (string)
: An identifier string that the AS can use to identify the
    particular instance of this client software. The content and structure of
    this identifier is opaque to the client instance.

~~~
"client": {
    "instance_id": "client-541-ab"
}
~~~

If there are no additional fields to send, the client instance MAY send the instance 
identifier as a direct reference value in lieu of the object.

~~~
"client": "client-541-ab"
~~~

When the AS receives a request with an instance identifier, the AS MUST
ensure that the key used to [sign the request](#binding-keys) is 
associated with the instance identifier.

If the `instance_id` field is sent, it MUST NOT be accompanied by other fields unless such 
fields are explicitly marked safe for inclusion alongside the instance
identifier. 

\[\[ [See issue #45](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/45) \]\]

If the AS does not recognize the instance identifier, the request MUST be rejected
with an error.

If the client instance is identified in this manner, the registered key for the client instance
MAY be a symmetric key known to the AS. The client instance MUST NOT send a
symmetric key by value in the request, as doing so would expose
the key directly instead of proving possession of it. 

### Providing Displayable Client Instance Information {#request-display}

If the client instance has additional information to display to the RO
during any interactions at the AS, it MAY send that information in the
"display" field. This field is a JSON object that declares information
to present to the RO during any interactive sequences.


name (string)
: Display name of the client software

uri (string)
: User-facing web page of the client software

logo_uri (string)
: Display image to represent the client
            software


~~~
    "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
    }
~~~

\[\[ [See issue #48](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/48) \]\]

Additional display fields are defined by [a registry TBD](#IANA).

The AS SHOULD use these values during interaction with the RO.
The values are for informational purposes only and MUST NOT
be taken as authentic proof of the client instance's identity or source.
The AS MAY restrict display values to specific client instances, as identified
by their keys in {{request-client}}.

### Authenticating the Client Instance {#request-key-authenticate}

If the presented key is known to the AS and is associated with a single instance
of the client software, the process of presenting a key and proving possession of that key 
is sufficient to authenticate the client instance to the AS. The AS MAY associate policies
with the client instance identified by this key, such as limiting which resources
can be requested and which interaction methods can be used. For example, only
specific client instances with certain known keys might be trusted with access tokens without the
AS interacting directly with the RO as in {{example-no-user}}.

The presentation of a key allows the AS to strongly associate multiple
successive requests from the same client instance with each other. This
is true when the AS knows the key ahead of time and can use the key to
authenticate the client instance, but also if the key is
ephemeral and created just for this series of requests. As such the
AS MAY allow for client instances to make requests with unknown keys. This pattern allows
for ephemeral client instances, such as single-page applications, and client software with many individual long-lived instances,
such as mobile applications, to generate key pairs per instance and use the keys within
the protocol without having to go through a separate registration step.
The AS MAY limit which capabilities are made available to client instances
with unknown keys. For example, the AS could have a policy saying that only
previously-registered client instances can request particular resources, or that all
client instances with unknown keys have to be interactively approved by an RO. 

## Identifying the User {#request-user}

If the client instance knows the identity of the end-user through one or more
identifiers or assertions, the client instance MAY send that information to the
AS in the "user" field. The client instance MAY pass this information by value
or by reference.

sub_ids (array of objects)
: An array of subject identifiers for the
            end-user, as defined by {{I-D.ietf-secevent-subject-identifiers}}.

assertions (object)
: An object containing assertions as values keyed on the assertion 
    type defined by [a registry TBD](#IANA). Possible keys include
    `id_token` for an {{OIDC}} ID Token and `saml2` for a SAML 2 assertion. Additional
    assertion values are defined by [a registry TBD](#IANA).
    \[\[ [See issue #41](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/41) \]\]

~~~
"user": {
   "sub_ids": [ {
     "subject_type": "email",
     "email": "user@example.com"
   } ],
   "assertions": {
     "id_token": "eyj..."
   }
}
~~~



Subject identifiers are hints to the AS in determining the
RO and MUST NOT be taken as declarative statements that a particular
RO is present at the client instance and acting as the end-user. Assertions SHOULD be validated by the AS. 
\[\[ [See issue #49](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/49) \]\]

If the identified end-user does not match the RO present at the AS
during an interaction step, the AS SHOULD reject the request with an error.

\[\[ [See issue #50](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/50) \]\]

If the AS trusts the client instance to present verifiable assertions, the AS MAY
decide, based on its policy, to skip interaction with the RO, even
if the client instance provides one or more interaction modes in its request.


### Identifying the User by Reference {#request-user-reference}

User reference identifiers can be dynamically
[issued by the AS](#response-dynamic-handles) to allow the client instance 
to represent the same end-user to the AS over subsequent requests.

If the client instance has a reference for the end-user at this AS, the
client instance MAY pass that reference as a string. The format of this string
is opaque to the client instance.

~~~
"user": "XUT2MFM1XBIKJKSDU8QM"
~~~

User reference identifiers are not intended to be human-readable
user identifiers or structured assertions. For the client instance to send
either of these, use the full [user request object](#request-user) instead.

\[\[ [See issue #51](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/51) \]\]

If the AS does not recognize the user reference, it MUST 
return an error.

## Interacting with the User {#request-interact}

Many times, the AS will require interaction with the RO in order to
approve a requested delegation to the client instance for both access to resources and direct
subject information. Many times the end-user using the client instance is the same person as
the RO, and the client instance can directly drive interaction with the AS by redirecting
the end-user on the same device, or by launching an application. Other times, the 
client instance can provide information to start the RO's interaction on a secondary
device, or the client instance will wait for the RO to approve the request asynchronously.
The client instance could also be signaled that interaction has completed by the AS making
callbacks. To facilitate all of these modes, the client instance declares the means that it 
can interact using the `interact` field. 

The `interact` field is a JSON object with three keys whose values declare how the client can initiate
and complete the request, as well as provide hints to the AS about user preferences such as locale. 
A client instance MUST NOT declare an interaction mode it does not support.
The client instance MAY send multiple modes in the same request.
There is no preference order specified in this request. An AS MAY
[respond to any, all, or none of the presented interaction modes](#response-interact) in a request, depending on
its capabilities and what is allowed to fulfill the request. 

start (list of strings/objects)
: Indicates how the client instance can start an interaction.

finish (object)
: Indicates how the client instance can receive an indication that interaction has finished at the AS.

hints (object)
: Provides additional information to inform the interaction process at the AS.


The `interact` field MUST contain the `start` key, and MAY contain the `finish` and `hints` keys. The value
of each key is an array which contains strings or JSON objects as defined below.

### Start Mode Definitions

This specification defines the following interaction start modes as an array of string values under the `start` key:

"redirect"
: Indicates that the client instance can direct the end-user to an arbitrary URL
    at the AS for interaction. {{request-interact-redirect}}

"app"
: Indicates that the client instance can launch an application on the end-user's
    device for interaction. {{request-interact-app}}

"user_code"
: Indicates that the client instance can communicate a human-readable short
    code to the end-user for use with a stable URL at the AS. {{request-interact-usercode}}

### Finish Mode Definitions

This specification defines the following interaction completion methods:

"redirect"
: Indicates that the client instance can receive a redirect from the end-user's device
    after interaction with the RO has concluded. {{request-interact-callback-redirect}}

"push"
: Indicates that the client instance can receive an HTTP POST request from the AS
    after interaction with the RO has concluded. {{request-interact-callback-push}}

### Hint Definitions

This specification defines the following properties under the `hints` key:

ui_locales (array of strings)
: Indicates the end-user's preferred locales that the AS can use
    during interaction, particularly before the RO has 
    authenticated. {{request-interact-locale}}

The following sections detail requests for interaction
modes. Additional interaction modes are defined in 
[a registry TBD](#IANA).

### Example Interactions

In this non-normative example, the client instance is indicating that it can [redirect](#request-interact-redirect)
the end-user to an arbitrary URL and can receive a [redirect](#request-interact-callback-redirect) through
a browser request.

~~~
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return/123455",
            "nonce": "LKLTI25DK82FX4T4QFZC"
        }
    }
~~~

In this non-normative example, the client instance is indicating that it can 
display a [user code](#request-interact-usercode) and direct the end-user
to an [arbitrary URL](#request-interact-redirect) on a secondary
device, but it cannot accept a redirect or push callback.

~~~
    "interact": {
        "start": ["redirect", "user_code"]
    }
~~~

If the client instance does not provide a suitable interaction mechanism, the
AS cannot contact the RO asynchronously, and the AS determines 
that interaction is required, then the AS SHOULD return an 
error since the client instance will be unable to complete the
request without authorization.

The AS SHOULD apply suitable timeouts to any interaction mechanisms
provided, including user codes and redirection URLs. The client instance SHOULD
apply suitable timeouts to any callback URLs.

### Start Interaction Modes

#### Redirect to an Arbitrary URL {#request-interact-redirect}

If the client instance is capable of directing the end-user to a URL defined
by the AS at runtime, the client instance indicates this by sending the
"redirect" field with the boolean value "true". The means by which
the client instance will activate this URL is out of scope of this
specification, but common methods include an HTTP redirect,
launching a browser on the end-user's device, providing a scannable
image encoding, and printing out a URL to an interactive
console.

~~~
"interact": {
  "start": ["redirect"]
}
~~~

If this interaction mode is supported for this client instance and
request, the AS returns a redirect interaction response {{response-interact-redirect}}.

#### Open an Application-specific URL {#request-interact-app}

If the client instance can open a URL associated with an application on
the end-user's device, the client instance indicates this by sending the "app"
field with boolean value "true". The means by which the client instance
determines the application to open with this URL are out of scope of
this specification.

~~~
"interact": {
   "start": ["app"]
}
~~~

If this interaction mode is supported for this client instance and
request, the AS returns an app interaction response with an app URL
payload {{response-interact-app}}.

\[\[ [See issue #54](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/54) \]\]

#### Display a Short User Code {#request-interact-usercode}

If the client instance is capable of displaying or otherwise communicating
a short, human-entered code to the RO, the client instance indicates this
by sending the "user_code" field with the boolean value "true". This
code is to be entered at a static URL that does not change at
runtime, as described in {{response-interact-usercode}}.

~~~
"interact": {
    "start": ["user_code"]
}
~~~

If this interaction mode is supported for this client instance and
request, the AS returns a user code and interaction URL as specified
in {{interaction-usercode}}.


### Finish Interaction Modes {#finish-interaction-modes}

If the client instance is capable of receiving a message from the AS indicating
that the RO has completed their interaction, the client instance
indicates this by sending the following members of an object under the `finish` key.

method (string)
: REQUIRED. The callback method that the AS will use to contact the client instance.
              Valid values include `redirect` {{request-interact-callback-redirect}}
              and `push` {{request-interact-callback-push}}, with other values
              defined by [a registry TBD](#IANA).

uri (string)
: REQUIRED. Indicates the URI that the AS will either send the RO to
              after interaction or send an HTTP POST request. This URI MAY be unique per request and MUST
              be hosted by or accessible by the client instance. This URI MUST NOT contain
              any fragment component. This URI MUST be protected by HTTPS, be
              hosted on a server local to the RO's browser ("localhost"), or
              use an application-specific URI scheme. If the client instance needs any
              state information to tie to the front channel interaction
              response, it MUST use a unique callback URI to link to
              that ongoing state. The allowable URIs and URI patterns MAY be restricted by the AS
              based on the client instance's presented key information. The callback URI
              SHOULD be presented to the RO during the interaction phase
              before redirect. 

nonce (string)
: REQUIRED. Unique value to be used in the
              calculation of the "hash" query parameter sent to the callback URL,
              must be sufficiently random to be unguessable by an attacker.
              MUST be generated by the client instance as a unique value for this
              request.

hash_method (string)
: OPTIONAL. The hash calculation
              mechanism to be used for the callback hash in {{interaction-hash}}. Can be one of `sha3` or `sha2`. If
              absent, the default value is `sha3`.
              \[\[ [See issue #56](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/56) \]\] 

If this interaction mode is supported for this client instance and
request, the AS returns a nonce for use in validating 
[the callback response](#response-interact-callback).
Requests to the callback URI MUST be processed as described in 
{{interaction-finalize}}, and the AS MUST require
presentation of an interaction callback reference as described in
{{continue-after-interaction}}.

\[\[ [See issue #58](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/58) \]\]

\[\[ [See issue #59](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/59) \]\]

#### Receive an HTTP Callback Through the Browser {#request-interact-callback-redirect}

A finish `method` value of `redirect` indicates that the client instance
will expect a request from the RO's browser using the HTTP method
GET as described in {{interaction-callback}}.

~~~
"interact": {
    "finish": {
        "method": "redirect",
        "uri": "https://client.example.net/return/123455",
        "nonce": "LKLTI25DK82FX4T4QFZC"
    }
}
~~~

Requests to the callback URI MUST be processed by the client instance as described in 
{{interaction-callback}}.

Since the incoming request to the callback URL is from the RO's
browser, this method is usually used when the RO and end-user are the
same entity. As such, the client instance MUST ensure the end-user is present on the request to
prevent substitution attacks.

#### Receive an HTTP Direct Callback {#request-interact-callback-push}

A finish `method` value of `push` indicates that the client instance will
expect a request from the AS directly using the HTTP method POST
as described in {{interaction-pushback}}.

~~~
"interact": {
    "finish": {
        "method": "push",
        "uri": "https://client.example.net/return/123455",
        "nonce": "LKLTI25DK82FX4T4QFZC"
    }
}
~~~

Requests to the callback URI MUST be processed by the client instance as described in 
{{interaction-pushback}}.

Since the incoming request to the callback URL is from the AS and
not from the RO's browser, the client instance MUST NOT require the end-user to
be present on the incoming HTTP request.

\[\[ [See issue #60](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/60) \]\]

### Hints

The `hints` key is an object describing one or more suggestions from the client
instance that the AS can use to help drive user interaction.

#### Indicate Desired Interaction Locales {#request-interact-locale}

If the client instance knows the end-user's locale and language preferences, the
client instance can send this information to the AS using the `ui_locales` field
with an array of locale strings as defined by {{RFC5646}}.

~~~
"interact": {
    "hints": {
        "ui_locales": ["en-US", "fr-CA"]
    }
}
~~~

If possible, the AS SHOULD use one of the locales in the array, with
preference to the first item in the array supported by the AS. If none
of the given locales are supported, the AS MAY use a default locale.

### Extending Interaction Modes {#request-interact-extend}

Additional interaction modes are defined in [a registry TBD](#IANA).

## Declaring Client Capabilities {#request-capabilities}

If the client software supports extension capabilities, the client instance MAY present them
to the AS in the "capabilities" field. This field is an array of
strings representing specific extensions and capabilities, as defined
by [a registry TBD](#IANA).

~~~
"capabilities": ["ext1", "ext2"]
~~~

## Referencing an Existing Grant Request {#request-existing}

If the client instance has a reference handle from a previously granted
request, it MAY send that reference in the "existing_grant" field. This
field is a single string consisting of the `value` of the `access_token`
returned in a previous request's [continuation response](#response-continue).

~~~
"existing_grant": "80UPRY5NM33OMUKMKSKU"
~~~

The AS MUST dereference the grant associated with the reference and
process this request in the context of the referenced one. The AS 
MUST NOT alter the existing grant associated with the reference.

\[\[ [See issue #62](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/62) \]\]

## Extending The Grant Request {#request-extending}

The request object MAY be extended by registering new items in 
[a registry TBD](#IANA). Extensions SHOULD be orthogonal to other parameters.
Extensions MUST document any aspects where the extension item affects or influences
the values or behavior of other request and response objects. 

# Grant Response {#response}

In response to a client instance's request, the AS responds with a JSON object
as the HTTP entity body. Each possible field is detailed in the sections below


continue (object)
: Indicates that the client instance can continue the request by making one or
    more continuation requests. {{response-continue}}

access_token (object / array of objects)
: A single access token or set of access tokens that the client instance can use to call the RS on
    behalf of the RO. {{response-token-single}}

interact (object)
: Indicates that interaction through some set of defined mechanisms
    needs to take place. {{response-interact}}

subject (object)
: Claims about the RO as known and declared by the AS. {{response-subject}}

instance_id (string)
: An identifier this client instance can use to identify itself when making 
    future requests. {{response-dynamic-handles}}

user_handle (string)
: An identifier this client instance can use to identify its current end-user when
    making future requests. {{response-dynamic-handles}}

error (object)
: An error code indicating that something has gone wrong. {{response-error}}

In this example, the AS is returning an [interaction URL](#response-interact-redirect),
a [callback nonce](#response-interact-callback), and a [continuation response](#response-continue).

~~~
{
    "interact": {
        "redirect": "https://server.example.com/interact/4CF492MLVMSW9MKMXKHQ",
        "push": "MBDOFXG4Y5CVJCX821LH"
    },
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/tx"
    }
}
~~~

In this example, the AS is returning a bearer [access token](#response-token-single)
with a management URL and a [subject identifier](#response-subject) in the form of
an email address.

~~~
{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": false,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L"
    },
    "subject": {
        "sub_ids": [ {
           "subject_type": "email",
           "email": "user@example.com",
        } ]
    }
}
~~~

## Request Continuation {#response-continue}

If the AS determines that the request can be continued with
additional requests, it responds with the "continue" field. This field
contains a JSON object with the following properties.


uri (string)
: REQUIRED. The URI at which the client instance can make
            continuation requests. This URI MAY vary per
            request, or MAY be stable at the AS if the AS includes
            an access token. The client instance MUST use this
            value exactly as given when making a [continuation request](#continue-request).

wait (integer)
: RECOMMENDED. The amount of time in integer
            seconds the client instance SHOULD wait after receiving this continuation
            handle and calling the URI.

access_token (object)
: REQUIRED. A unique access token for continuing the request, in the format specified
            in {{response-token-single}}. This access token MUST be bound to the
            client instance's key used in the request and MUST NOT be a `bearer` token. As a consequence,
            the `bound` field of this access token is always the boolean value `true` and the
            `key` field MUST be omitted.
            This access token MUST NOT be usable at resources outside of the AS.
            The client instance MUST present the access token in all requests to the continuation URI as 
            described in {{use-access-token}}.
            \[\[ [See issue #66](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/66) \]\]

~~~
{
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 60
    }
}
~~~



The client instance can use the values of this field to continue the
request as described in {{continue-request}}. Note that the
client instance MUST sign all continuation requests with its key as described
in {{binding-keys}} and
MUST present the access token in its continuation request.

This field SHOULD be returned when interaction is expected, to
allow the client instance to follow up after interaction has been
concluded.

## Access Tokens {#response-token}

If the AS has successfully granted one or more access tokens to the client instance,
the AS responds with the `access_token` field. This field contains either a single
access token as described in {{response-token-single}} or an array of access tokens
as described in {{response-token-multiple}}.

The client instance uses any access tokens in this response to call the RS as
described in {{use-access-token}}.

### Single Access Token {#response-token-single}

If the client instance has requested a single access token and the AS has
granted that access token, the AS responds with the "access_token"
field. The value of this field is an object with the following
properties.


value (string)
: REQUIRED. The value of the access token as a
    string. The value is opaque to the client instance. The value SHOULD be
    limited to ASCII characters to facilitate transmission over HTTP
    headers within other protocols without requiring additional encoding.

bound (boolean)
: RECOMMENDED. Flag indicating if the token is bound to the client instance's key.
    If the boolean value is `true` or the field is omitted, and the `key` field is omitted,
    the token is bound to the [key used by the client instance](#request-client) in its request 
    for access. If the boolean value is `true` or the field is omitted, and the `key` field
    is present, the token is bound to the key and proofing mechanism indicated in the
    `key` field. If the boolean value is `false`, the token is a bearer token with no
    key bound to it and the `key` field MUST be omitted.

label (string)
: REQUIRED for multiple access tokens, OPTIONAL for single access token. 
    The value of the `label` the client instance provided in the associated
    [token request](#request-token), if present. If the token has been split
    by the AS, the value of the `label` field is chosen by the AS and the
    `split` field is included and set to `true`.

manage (string)
: OPTIONAL. The management URI for this
    access token. If provided, the client instance MAY manage its access
    token as described in {{token-management}}. This management
    URI is a function of the AS and is separate from the RS
    the client instance is requesting access to.
    This URI MUST NOT include the
    access token value and SHOULD be different for each access
    token issued in a request.

access (array of objects/strings)
: RECOMMENDED. A description of the rights
    associated with this access token, as defined in 
    {{resource-access-rights}}. If included, this MUST reflect the rights
    associated with the issued access token. These rights MAY vary
    from what was requested by the client instance.

expires_in (integer)
: OPTIONAL. The number of seconds in
    which the access will expire. The client instance MUST NOT use the access
    token past this time. An RS MUST NOT accept an access token
    past this time. Note that the access token MAY be revoked by the
    AS or RS at any point prior to its expiration.

key (object / string)
: OPTIONAL. The key that the token is bound to, if different from the
    client instance's presented key. The key MUST be an object or string in a format
    described in {{key-format}}, describing a public key to which the
    client instance can use the associated private key. The client instance MUST be able to
    dereference or process the key information in order to be able
    to sign the request.

durable (boolean)
: OPTIONAL. Flag indicating a hint of AS behavior on token rotation.
    If this flag is set to the value `true`, then the client instance can expect
    a previously-issued access token to continue to work after it has been [rotated](#rotate-access-token)
    or the underlying grant request has been [modified](#continue-modify), resulting
    in the issuance of new access tokens. If this flag is set to the boolean value `false`
    or is omitted, the client instance can anticipate a given access token
    will stop working after token rotation or grant request modification.
    Note that a token flagged as `durable` can still expire or be revoked through
    any normal means.

split (boolean)
: OPTIONAL. Flag indicating that this token was generated by issuing multiple access tokens
    in response to one of the client instance's [token request](#request-token) objects.
    This behavior MUST NOT be used unless the client instance has specifically requested it
    by use of the `split` flag.

The following non-normative example shows a single access token  bound to the client instance's key
used in the initial request, with a management URL, and that has access to three described resources 
(one using an object and two described by reference strings).

~~~
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
        "access": [
            {
                "type": "photo-api",
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            },
            "read", "dolphin-metadata"
        ]
    }
~~~

The following non-normative example shows a single bearer access token
with access to two described resources.

~~~
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "access": [
            "finance", "medical"
        ]
    }
~~~


If the client instance [requested a single access token](#request-token-single), the AS MUST NOT respond with the multiple
access token structure unless the client instance sends the `split` flag as described in {{request-token-single}}.

If the AS has split the access token response, the response MUST include the `split` flag set to `true`.

\[\[ [See issue #69](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/69) \]\]

### Multiple Access Tokens {#response-token-multiple}

If the client instance has requested multiple access tokens and the AS has
granted at least one of them, the AS responds with the
"access_token" field. The value of this field is a JSON
array, the members of which are distinct access
tokens as described in {{response-token-single}}.
Each object MUST have a unique `label` field, corresponding to the token labels
chosen by the client instance in the [multiple access token request](#request-token-multiple).

In this non-normative example, two bearer tokens are issued under the
names `token1` and `token2`, and only the first token has a management
URL associated with it.

~~~
    "access_token": [
        {
            "label": "token1",
            "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
            "bound": true,
            "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
            "access": [ "finance" ]
        },
        {
            "label": "token2",
            "value": "UFGLO2FDAFG7VGZZPJ3IZEMN21EVU71FHCARP4J1",
            "bound": true,
            "access": [ "medical" ]
        }
    }
~~~

Each access token corresponds to one of the objects in the `access_token` array of
the client instance's [request](#request-token-multiple). 

The multiple access token response MUST be used when multiple access tokens are
requested, even if only one access token is issued as a result of the request.
The AS MAY refuse to issue one or more of the
requested access tokens, for any reason. In such cases the refused token is omitted
from the response and all of the other issued access
tokens are included in the response the requested names appropriate names.

If the client instance [requested multiple access tokens](#request-token-multiple), the AS MUST NOT respond with a
single access token structure, even if only a single access token is granted. In such cases, the AS responds
with a multiple access token structure containing one access token.

If the AS has split the access token response, the response MUST include the `split` flag set to `true`.

~~~
    "access_token": [
        {
            "label": "split-1",
            "value": "8N6BW7OZB8CDFONP219-OS9M2PMHKUR64TBRP1LT0",
            "bound": true,
            "split": true,
            "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
            "access": [ "fruits" ]
        },
        {
            "label": "split-2",
            "value": "FG7VGZZPJ3IZEMN21EVU71FHCAR-UFGLO2FDAP4J1",
            "bound": true,
            "split": true,
            "access": [ "vegetables" ]
        }
    }
~~~

Each access token MAY be bound to different keys with different proofing mechanisms.

If [token management](#token-management) is allowed, each access token SHOULD have different `manage` URIs.

\[\[ [See issue #70](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/70) \]\]

## Interaction Modes {#response-interact}

If the client instance has indicated a [capability to interact with the RO in its request](#request-interact),
and the AS has determined that interaction is both
supported and necessary, the AS responds to the client instance with any of the
following values in the `interact` field of the response. There is 
no preference order for interaction modes in the response, 
and it is up to the client instance to determine which ones to use. All supported
interaction methods are included in the same `interact` object.

redirect (string)
: Redirect to an arbitrary URL. {{response-interact-redirect}}

app (string)
: Launch of an application URL. {{response-interact-app}}

finish (string)
: A nonce used by the client instance to verify the callback after interaction is completed. {{response-interact-callback}}

user_code (object)
: Display a short user code. {{response-interact-usercode}}

Additional interaction mode responses can be defined in [a registry TBD](#IANA).

The AS MUST NOT respond with any interaction mode that the
client instance did not indicate in its request. The AS MUST NOT respond with
any interaction mode that the AS does not support. Since interaction
responses include secret or unique information, the AS SHOULD
respond to each interaction mode only once in an ongoing request,
particularly if the client instance [modifies its request](#continue-modify).

### Redirection to an arbitrary URL {#response-interact-redirect}

If the client instance indicates that it can [redirect to an arbitrary URL](#request-interact-redirect) and the AS supports this mode for the client instance's
request, the AS responds with the "redirect" field, which is
a string containing the URL to direct the end-user to. This URL MUST be
unique for the request and MUST NOT contain any security-sensitive
information.

~~~
    "interact": {
        "redirect": "https://interact.example.com/4CF492MLVMSW9MKMXKHQ"
    }
~~~

The interaction URL returned represents a function of the AS but MAY be completely
distinct from the URL the client instance uses to [request access](#request), allowing an
AS to separate its user-interactive functionality from its back-end security
functionality.

\[\[ [See issue #72](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/72) \]\]

The client instance sends the end-user to the URL to interact with the AS. The
client instance MUST NOT alter the URL in any way. The means for the client instance
to send the end-user to this URL is out of scope of this specification,
but common methods include an HTTP redirect, launching the system
browser, displaying a scannable code, or printing out the URL in an
interactive console.

### Launch of an application URL {#response-interact-app}

If the client instance indicates that it can [launch an application URL](#request-interact-app) and
the AS supports this mode for the client instance's request, the AS
responds with the "app" field, which is a string containing the URL
to direct the end-user to. This URL MUST be unique for the request and
MUST NOT contain any security-sensitive information.

~~~
    "interact": {
        "app": "https://app.example.com/launch?tx=4CF492MLV"
    }
~~~



The client instance launches the URL as appropriate on its platform, and
the means for the client instance to launch this URL is out of scope of this
specification. The client instance MUST NOT alter the URL in any way. The
client instance MAY attempt to detect if an installed application will
service the URL being sent before attempting to launch the
application URL.

\[\[ [See issue #71](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/71) \]\]

### Post-interaction Callback to a Client Instance Accessible URL {#response-interact-callback}

If the client instance indicates that it can [receive a post-interaction redirect or push at a URL](#finish-interaction-modes) 
and the AS supports this mode for the
client instance's request, the AS responds with a `finish` field containing a nonce
that the client instance will use in validating the callback as defined in
{{interaction-finalize}}.

~~~
    "interact": {
        "finish": "MBDOFXG4Y5CVJCX821LH"
    }
~~~

When the RO completes interaction at the AS, the AS MUST either redirect the RO's browser
or send an HTTP POST to the client instance's callback URL using the method indicated in the
[interaction request](#finish-interaction-modes) as described in {{interaction-finalize}}.

If the AS returns a nonce, the client instance MUST NOT
continue a grant request before it receives the associated
interaction reference on the callback URI.

### Display of a Short User Code {#response-interact-usercode}

If the client instance indicates that it can 
[display a short user-typeable code](#request-interact-usercode)
and the AS supports this mode for the client instance's
request, the AS responds with a "user_code" field. This field is an
object that contains the following members.


code (string)
: REQUIRED. A unique short code that the user
              can type into an authorization server. This string MUST be
              case-insensitive, MUST consist of only easily typeable
              characters (such as letters or numbers). The time in which this
              code will be accepted SHOULD be short lived, such as several
              minutes. It is RECOMMENDED that this code be no more than eight
              characters in length.

url (string)
: RECOMMENDED. The interaction URL that the client instance
              will direct the RO to. This URL MUST be stable at the AS such
              that client instance's can be statically configured with it.


~~~
    "interact": {
        "user_code": {
            "code": "A1BC-3DFF",
            "url": "https://srv.ex/device"
        }
    }
~~~

The client instance MUST communicate the "code" to the end-user in some
fashion, such as displaying it on a screen or reading it out
audibly. The `code` is a one-time-use credential that the AS uses to identify
the pending request from the client instance. When the RO [enters this code](#interaction-usercode) into the
AS, the AS MUST determine the pending request that it was associated
with. If the AS does not recognize the entered code, the AS MUST
display an error to the user. If the AS detects too many unrecognized codes
entered, it SHOULD display an error to the user.

The client instance SHOULD also communicate the URL if possible
to facilitate user interaction, but since the URL should be stable,
the client instance should be able to safely decide to not display this value.
As this interaction mode is designed to facilitate interaction
via a secondary device, it is not expected that the client instance redirect
the end-user to the URL given here at runtime. Consequently, the URL needs to 
be stable enough that a client instance could be statically configured with it, perhaps
referring the end-user to the URL via documentation instead of through an
interactive means. If the client instance is capable of communicating an
arbitrary URL to the end-user, such as through a scannable code, the
client instance can use the ["redirect"](#request-interact-redirect) mode
for this purpose instead of or in addition to the user code mode.

The interaction URL returned represents a function of the AS but MAY be completely
distinct from the URL the client instance uses to [request access](#request), allowing an
AS to separate its user-interactive functionality from its back-end security
functionality.

\[\[ [See issue #72](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/72) \]\]

### Extending Interaction Mode Responses {#response-interact-extend}

Extensions to this specification can define new interaction
mode responses in [a registry TBD](#IANA). Extensions MUST
document the corresponding interaction request.



## Returning User Information {#response-subject}

If information about the RO is requested and the AS
grants the client instance access to that data, the AS returns the approved
information in the "subject" response field. This field is an object
with the following OPTIONAL properties.


sub_ids (array of objects)
: An array of subject identifiers for the
            RO, as defined by 
            {{I-D.ietf-secevent-subject-identifiers}}.

assertions (object)
: An object containing assertions as values
            keyed on the assertion type defined by [a registry TBD](#IANA). 
            \[\[ [See issue #41](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/41) \]\]

updated_at (string)
: Timestamp as an ISO8610 date string, indicating
            when the identified account was last updated. The client instance MAY use
            this value to determine if it needs to request updated profile
            information through an identity API. The definition of such an
            identity API is out of scope for this specification.


~~~
"subject": {
   "sub_ids": [ {
     "subject_type": "email",
     "email": "user@example.com",
   } ],
   "assertions": {
     "id_token": "eyj..."
   }
}
~~~

The AS MUST return the `subject` field only in cases where the AS is sure that
the RO and the end-user are the same party. This can be accomplished through some forms of
[interaction with the RO](#user-interaction).

Subject identifiers returned by the AS SHOULD uniquely identify the RO at the
AS. Some forms of subject identifier are opaque to the client instance (such as the subject of an 
issuer and subject pair), while others forms (such as email address and phone number) are
intended to allow the client instance to correlate the identifier with other account information
at the client instance. The client instance MUST NOT request or use any returned subject identifiers for communication
purposes (see {{request-subject}}). That is, a subject identifier returned in the format of an email address or 
a phone number only identifies the RO to the AS and does not indicate that the
AS has validated that the represented email address or phone number in the identifier
is suitable for communication with the current user. To get such information,
the client instance MUST use an identity protocol to request and receive additional identity
claims. The details of an identity protocol and associated schema 
are outside the scope of this specification.

\[\[ [See issue #75](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/75) \]\]

Extensions to this specification MAY define additional response
properties in [a registry TBD](#IANA).

## Returning Dynamically-bound Reference Handles {#response-dynamic-handles}

Many parts of the client instance's request can be passed as either a value
or a reference. The use of a reference in place of a value allows
for a client instance to optimize requests to the AS.

Some references, such as for the [client instance's identity](#request-instance) 
or the [requested resources](#resource-access-reference), can be managed statically through an
admin console or developer portal provided by the AS or RS. The developer
of the client software can include these values in their code for a more
efficient and compact request.

If desired, the AS MAY also generate and return some of these references
dynamically to the client instance in its response to facilitate multiple
interactions with the same software. The client instance SHOULD use these
references in future requests in lieu of sending the associated data
value. These handles are intended to be used on future requests.

Dynamically generated handles are string values that MUST be
protected by the client instance as secrets. Handle values MUST be unguessable
and MUST NOT contain any sensitive information. Handle values are
opaque to the client instance. 

All dynamically generated handles are returned as fields in the
root JSON object of the response. This specification defines the
following dynamic handle returns, additional handles can be defined in
[a registry TBD](#IANA).


instance_id (string)
: A string value used to represent the information
            in the `client` object that the client instance can use in a future request, as
            described in {{request-instance}}.

user_handle (string)
: A string value used to represent the current
            user. The client instance can use in a future request, as described in
            {{request-user-reference}}.


This non-normative example shows two handles along side an issued
access token.

~~~
{
    "user_handle": "XUT2MFM1XBIKJKSDU8QM",
    "instance_id": "7C7C4AZ9KHRS6X63AJAO",
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true
    }
}
~~~

\[\[ [See issue #77](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/77) \]\]

\[\[ [See issue #78](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/78) \]\]

## Error Response {#response-error}

If the AS determines that the request cannot be issued for any
reason, it responds to the client instance with an error message.


error (string)
: The error code.


~~~
{

  "error": "user_denied"

}
~~~



The error code is one of the following, with additional values
available in [a registry TBD](#IANA):


user_denied
: The RO denied the request.

too_fast
: The client instance did not respect the timeout in the
            wait response.

unknown_request
: The request referenced an unknown ongoing access request.

\[\[ [See issue #79](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/79) \]\]

## Extending the Response {#response-extend}

Extensions to this specification MAY define additional fields for
the grant response in [a registry TBD](#IANA).

# Interaction at the AS {#user-interaction}

If the client instance [indicates that it is capable of driving interaction with the RO in its request](#request-interact), and
the AS determines that interaction is required and responds to one or
more of the client instance's interaction modes, the client instance SHOULD
initiate one of the returned 
[interaction modes in the response](#response-interact).

When the RO is interacting with the AS, the AS MAY perform whatever
actions it sees fit, including but not limited to:

- authenticate the current user (who may be the end-user) as the RO

- gather consent and authorization from the RO for access to
          requested resources and direct information

- allow the RO to modify the parameters of the request (such as
          disallowing some requested resources or specifying an account or
          record)

- provide warnings to the RO about potential attacks or negative
    effects of the requested information

## Interaction at a Redirected URI {#interaction-redirect}

When the RO is directed to the AS through the ["redirect"](#response-interact-redirect)
mode, the AS can interact with the RO through their web
browser to authenticate the user as an RO and gather their consent.
Note that since the client instance does not add any parameters to the URL, the
AS MUST determine the grant request being referenced from the URL
value itself. If the URL cannot be associated with a currently active
request, the AS MUST display an error to the RO and MUST NOT attempt
to redirect the RO back to any client instance even if a [redirect is supplied](#request-interact-callback-redirect).

The interaction URL MUST be reachable from the RO's browser, though
note that the RO MAY open the URL on a separate device from the client instance
itself. The interaction URL MUST be accessible from an HTTP GET
request, and MUST be protected by HTTPS or equivalent means.

With this method, it is common for the RO to be the same party as the end-user, since
the client instance has to communicate the redirection URI to the end-user.

## Interaction at the User Code URI {#interaction-usercode}

When the RO is directed to the AS through the ["user_code"](#response-interact-usercode) mode, the
AS can interact with the RO through their web browser to collect the
user code, authenticate the user as an RO, and gather their consent.
Note that since the URL itself is static, the AS MUST determine the
grant request being referenced from the user code value itself. If the
user code cannot be associated with a currently active request, the AS
MUST display an error to the RO and MUST NOT attempt to redirect the
RO back to any client instance even if a [redirect is supplied](#request-interact-callback-redirect).

The user code URL MUST be reachable from the RO's browser, though
note that the RO MAY open the URL on a separate device from the client instance
itself. The user code URL MUST be accessible from an HTTP GET request,
and MUST be protected by HTTPS or equivalent means.

While it is common for the RO to be the same party as the end-user, since
the client instance has to communicate the user code to someone, there are
cases where the end-user and RO are separate parties and the authorization
happens asynchronously.


## Interaction through an Application URI {#interaction-app}

When the client instance successfully launches an application through the
["app" mode](#response-interact-app), the AS
interacts with the RO through that application to authenticate the
user as the RO and gather their consent. The details of this
interaction are out of scope for this specification.

## Post-Interaction Completion {#interaction-finalize}

Upon completing an interaction with the RO, if a ["callback"](#response-interact-callback) mode is
available with the current request, the AS MUST follow the appropriate
method at the end of interaction to allow the client instance to continue. If
this mode is not available, the AS SHOULD instruct the RO to
return to their client instance upon completion. Note that these steps
still take place in most error cases, such as when the RO has denied
access. This pattern allows the client instance to potentially recover from the error
state without restarting the request from scratch by modifying its
request or providing additional information directly to the AS.

The AS MUST create an interaction reference and associate that
reference with the current interaction and the underlying pending
request. This value MUST be sufficiently random so as not to be
guessable by an attacker. The interaction reference MUST be
one-time-use.

The AS MUST calculate a hash value based on the client instance and AS nonces and the
interaction reference, as described in 
{{interaction-hash}}. The client instance will use this value to
validate the return call from the AS.

The AS then MUST send the hash and interaction reference based on
the interaction finalization mode as described in the following
sections.

### Completing Interaction with a Browser Redirect to the Callback URI {#interaction-callback}

When using the [`redirect` interaction finish method](#response-interact-callback),
the AS signals to the client instance that interaction is
complete and the request can be continued by directing the RO (in
their browser) back to the client instance's redirect URL sent in [the callback request](#request-interact-callback-redirect).

The AS secures this redirect by adding the hash and interaction
reference as query parameters to the client instance's redirect URL.


hash
: REQUIRED. The interaction hash value as
              described in {{interaction-hash}}.

interact_ref
: REQUIRED. The interaction reference
              generated for this interaction.


The means of directing the RO to this URL are outside the scope
of this specification, but common options include redirecting the
RO from a web page and launching the system browser with the
target URL.

~~~
https://client.example.net/return/123455
  ?hash=p28jsq0Y2KK3WS__a42tavNC64ldGTBroywsWxT4md_jZQ1R2HZT8BOWYHcLmObM7XHPAdJzTZMtKBsaraJ64A
  &interact_ref=4IFWWIKYBC2PQ6U56NL1
~~~



When receiving the request, the client instance MUST parse the query
parameters to calculate and validate the hash value as described in
{{interaction-hash}}. If the hash validates, the client instance
sends a continuation request to the AS as described in 
{{continue-after-interaction}} using the interaction
reference value received here.

### Completing Interaction with a Direct HTTP Request Callback {#interaction-pushback}

When using the 
["callback" interaction mode](#response-interact-callback) with the `push` method,
the AS signals to the client instance that interaction is
complete and the request can be continued by sending an HTTP POST
request to the client instance's callback URL sent in [the callback request](#request-interact-callback-push).

The entity message body is a JSON object consisting of the
following two fields:


hash (string)
: REQUIRED. The interaction hash value as
              described in {{interaction-hash}}.

interact_ref (string)
: REQUIRED. The interaction reference
              generated for this interaction.


~~~
POST /push/554321 HTTP/1.1
Host: client.example.net
Content-Type: application/json

{
  "hash": "p28jsq0Y2KK3WS__a42tavNC64ldGTBroywsWxT4md_jZQ1R2HZT8BOWYHcLmObM7XHPAdJzTZMtKBsaraJ64A",
  "interact_ref": "4IFWWIKYBC2PQ6U56NL1"
}

~~~



When receiving the request, the client instance MUST parse the JSON object
and validate the hash value as described in 
{{interaction-hash}}. If the hash validates, the client instance sends
a continuation request to the AS as described in {{continue-after-interaction}} using the interaction
reference value received here.

### Calculating the interaction hash {#interaction-hash}

The "hash" parameter in the request to the client instance's callback URL ties
the front channel response to an ongoing request by using values
known only to the parties involved. This security mechanism allows the client instance to protect itself against
several kinds of session fixation and injection attacks. The AS MUST
always provide this hash, and the client instance MUST validate the hash when received.

To calculate the "hash" value, the party doing the calculation
first takes the "nonce" value sent by the client instance in the 
[interaction section of the initial request](#finish-interaction-modes), the AS's nonce value
from [the callback response](#response-interact-callback), and the "interact_ref"
sent to the client instance's callback URL.
These three values are concatenated to each other in this order
using a single newline character as a separator between the fields.
There is no padding or whitespace before or after any of the lines,
and no trailing newline character.

~~~
VJLO6A4CAYLBXHTR0KRO
MBDOFXG4Y5CVJCX821LH
4IFWWIKYBC2PQ6U56NL1
~~~

The party then hashes this string with the appropriate algorithm
based on the "hash_method" parameter of the "callback".
If the "hash_method" value is not present in the client instance's
request, the algorithm defaults to "sha3". 

\[\[ [See issue #56](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/56) \]\]

#### SHA3-512 {#hash-sha3}

The "sha3" hash method consists of hashing the input string
with the 512-bit SHA3 algorithm. The byte array is then encoded
using URL Safe Base64 with no padding. The resulting string is the
hash value.

~~~
p28jsq0Y2KK3WS__a42tavNC64ldGTBroywsWxT4md_jZQ1R2HZT8BOWYHcLmObM7XHPAdJzTZMtKBsaraJ64A
~~~


#### SHA2-512 {#hash-sha2}

The "sha2" hash method consists of hashing the input string
with the 512-bit SHA2 algorithm. The byte array is then encoded
using URL Safe Base64 with no padding. The resulting string is the
hash value.

~~~
62SbcD3Xs7L40rjgALA-ymQujoh2LB2hPJyX9vlcr1H6ecChZ8BNKkG_HrOKP_Bpj84rh4mC9aE9x7HPBFcIHw
~~~






# Continuing a Grant Request {#continue-request}

While it is possible for the AS to return a [response](#response) with all the
client instance's requested information (including [access tokens](#response-token) and 
[direct user information](#response-subject)), it's more common that the AS and
the client instance will need to communicate several times over the lifetime of an access grant.
This is often part of facilitating [interaction](#user-interaction), but it could
also be used to allow the AS and client instance to continue negotiating the parameters of
the [original grant request](#request). 

To enable this ongoing negotiation, the AS provides a continuation API to the client software.
The AS returns a `continue` field 
[in the response](#response-continue) that contains information the client instance needs to
access this API, including a URI to access
as well as an access token to use during the continued requests. 

The access token is initially bound to the same key and method the client instance used to make 
the initial request. As a consequence,
when the client instance makes any calls to the continuation URL, the client instance MUST present
the access token as described in {{use-access-token}} and present
proof of the client instance's key (or its most recent rotation)
by signing the request as described in {{binding-keys}}.
The AS MUST validate all keys presented by the client instance or referenced in an
ongoing request for each call within that request.

\[\[ [See issue #85](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/85) \]\]

For example, here the client instance makes a POST request to a unique URI and signs 
the request with detached JWS:

~~~
POST /continue/KSKUOMUKM HTTP/1.1
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Host: server.example.com
Detached-JWS: ejy0...
~~~

The AS MUST be able to tell from the client instance's request which specific ongoing request
is being accessed, using a combination of the continuation URL,
the provided access token, and the client instance identified by the key signature.
If the AS cannot determine a single active grant request to map the
continuation request to, the AS MUST return an error.

The ability to continue an already-started request allows the client instance to perform several 
important functions, including presenting additional information from interaction, 
modifying the initial request, and getting the current state of the request.

All requests to the continuation API are protected by this bound access token. 
For example, here the client instance makes a POST request to a stable continuation endpoint
URL with the [interaction reference](#continue-after-interaction), 
includes the access token, and signs with detached JWS:

~~~
POST /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...

{
  "interact_ref": "4IFWWIKYBC2PQ6U56NL1"
}
~~~

If a "wait" parameter was included in the [continuation response](#response-continue), the
client instance MUST NOT call the continuation URI prior to waiting the number of
seconds indicated. If no "wait" period is indicated, the client instance SHOULD
wait at least 5 seconds. If the client instance does not respect the
given wait period, the AS MUST return an error.
\[\[ [See issue #86](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/86) \]\]

The response from the AS is a JSON object and MAY contain any of the
fields described in {{response}}, as described in more detail in the
sections below.

If the AS determines that the client instance can 
make a further continuation request, the AS MUST include a new 
["continue" response](#response-continue). 
The new `continue` response MUST include a bound access token as well, and
this token SHOULD be a new access token, invalidating the previous access token.
If the AS does not return a new `continue` response, the client instance
MUST NOT make an additional continuation request. If a client instance does so,
the AS MUST return an error.
\[\[ [See issue #87](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/87) \]\]

For continuation functions that require the client instance to send a message body, the body MUST be
a JSON object. 

## Continuing After a Completed Interaction {#continue-after-interaction}

When the AS responds to the client instance's `callback` parameter as in {{interaction-callback}}, this
response includes an interaction reference. The client instance MUST include that value as the field
`interact_ref` in a POST request to the continuation URI.

~~~
POST /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...

{
  "interact_ref": "4IFWWIKYBC2PQ6U56NL1"
}
~~~

Since the interaction reference is a one-time-use value as described in {{interaction-callback}}, 
if the client instance needs to make additional continuation calls after this request, the client instance
MUST NOT include the interaction reference. If the AS detects a client instance submitting the same 
interaction reference multiple times, the AS MUST return an error and SHOULD invalidate
the ongoing request.

The [response](#response) MAY contain any newly-created [access tokens](#response-token) or
newly-released [subject claims](#response-subject). The response MAY contain
a new ["continue" response](#response-continue) as described above. The response
SHOULD NOT contain any [interaction responses](#response-interact).
\[\[ [See issue #89](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/89) \]\]

For example, if the request is successful in causing the AS to issue access tokens and
release subject claims, the response could look like this:

~~~
{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L"
    },
    "subject": {
        "sub_ids": [ {
           "subject_type": "email",
           "email": "user@example.com",
        } ]
    }
}
~~~

With this example, the client instance can not make an additional continuation request because
a `continue` field is not included.

\[\[ [See issue #88](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/88) \]\]

## Continuing During Pending Interaction {#continue-poll}

When the client instance does not include a `callback` parameter, the client instance will often need to
poll the AS until the RO has authorized the request. To do so, the client instance makes a POST
request to the continuation URI as in {{continue-after-interaction}}, but does not
include a message body.

~~~
POST /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...
~~~

The [response](#response) MAY contain any newly-created [access tokens](#response-token) or
newly-released [subject claims](#response-subject). The response MAY contain
a new ["continue" response](#response-continue) as described above. If a `continue`
field is included, it SHOULD include a `wait` field to facilitate a reasonable polling rate by
the client instance. The response SHOULD NOT contain [interaction responses](#response-interact).

For example, if the request has not yet been authorized by the RO, the AS could respond
by telling the client instance to make another continuation request in the future. In this example,
a new, unique access token has been issued for the call, which the client instance will use in its
next continuation request. 

~~~
{
    "continue": {
        "access_token": {
            "value": "33OMUKMKSKU80UPRY5NM",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 30
    }
}
~~~

\[\[ [See issue #90](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/90) \]\]

\[\[ [See issue #91](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/91) \]\]

If the request is successful in causing the AS to issue access tokens and
release subject claims, the response could look like this example:

~~~
{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L"
    },
    "subject": {
        "sub_ids": [ {
           "subject_type": "email",
           "email": "user@example.com",
        } ]
    }
}
~~~

## Modifying an Existing Request {#continue-modify}

The client instance might need to modify an ongoing request, whether or not tokens have already been
issued or claims have already been released. In such cases, the client instance makes an HTTP PATCH
request to the continuation URI and includes any fields it needs to modify. Fields
that aren't included in the request are considered unchanged from the original request.

The client instance MAY include the `access_token` and `subject` fields as described in {{request-token}}
and {{request-subject}}. Inclusion of these fields override any values in the initial request,
which MAY trigger additional requirements and policies by the AS. For example, if the client instance is asking for 
more access, the AS could require additional interaction with the RO to gather additional consent.
If the client instance is asking for more limited access, the AS could determine that sufficient authorization
has been granted to the client instance and return the more limited access rights immediately. 
\[\[ [See issue #92](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/92) \]\]

The client instance MAY include the `interact` field as described in {{request-interact}}. Inclusion of
this field indicates that the client instance is capable of driving interaction with the RO, and this field
replaces any values from a previous request. The AS MAY respond to any of the interaction 
responses as described in {{response-interact}}, just like it would to a new request.

The client instance MAY include the `user` field as described in {{request-user}} to present new assertions
or information about the end-user. 
\[\[ [See issue #93](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/93) \]\]

The client instance MUST NOT include the `client` section of the request.
\[\[ [See issue #94](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/94) \]\]

The client instance MAY include post-interaction responses such as described in {{continue-after-interaction}}.
\[\[ [See issue #95](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/95) \]\]

Modification requests MUST NOT alter previously-issued access tokens. Instead, any access
tokens issued from a continuation are considered new, separate access tokens. The AS 
MAY revoke existing access tokens after a modification has occurred. 
\[\[ [See issue #96](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/96) \]\]

If the modified request can be granted immediately by the AS, 
the [response](#response) MAY contain any newly-created [access tokens](#response-token) or
newly-released [subject claims](#response-subject). The response MAY contain
a new ["continue" response](#response-continue) as described above. If interaction
can occur, the response SHOULD contain [interaction responses](#response-interact) as well.

For example, a client instance initially requests a set of resources using references:

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access": [
        "read", "write"
    ],
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return/123455",
            "nonce": "LKLTI25DK82FX4T4QFZC"
        }
    },
    "client": "987YHGRT56789IOLK"
}
~~~

Access is granted by the RO, and a token is issued by the AS. 
In its final response, the AS includes a `continue` field, which includes
a separate access token for accessing the continuation API:

~~~
{
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 30
    },
    "access_token": {
        "value": "RP1LT0-OS9M2P_R64TB",
        "bound": true,
        "access": [
            "read", "write"
        ]
    }
}
~~~

This `continue` field allows the client instance to make an eventual continuation call. In the future, 
the client instance realizes that it no longer needs
"write" access and therefore modifies its ongoing request, here asking for just "read" access
instead of both "read" and "write" as before.

~~~
PATCH /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            "read"
        ]
    }
    ...
}
~~~

The AS replaces the previous `access` from the first request, allowing the AS to
determine if any previously-granted consent already applies. In this case, the AS would
likely determine that reducing the breadth of the requested access means that new access
tokens can be issued to the client instance. The AS would likely revoke previously-issued access tokens
that had the greater access rights associated with them, unless they had been issued
with the `durable` flag.

~~~
{
    "continue": {
        "access_token": {
            "value": "M33OMUK80UPRY5NMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 30
    },
    "access_token": {
        "value": "0EVKC7-2ZKwZM_6N760",
        "bound": true,
        "access": [
            "read"
        ]
    }
}
~~~

For another example, the client instance initially requests read-only access but later 
needs to step up its access. The initial request could look like this example. 

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            "read"
        ]
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return/123455",
            "nonce": "LKLTI25DK82FX4T4QFZC"
        }
    },
    "client": "987YHGRT56789IOLK"
}
~~~

Access is granted by the RO, and a token is issued by the AS. 
In its final response, the AS includes a `continue` field:

~~~
{
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 30
    },
    "access_token": {
        "value": "RP1LT0-OS9M2P_R64TB",
        "bound": true,
        "access": [
            "read"
        ]
    }
}
~~~

This allows the client instance to make an eventual continuation call. The client instance later realizes that it now
needs "write" access in addition to the "read" access. Since this is an expansion of what
it asked for previously, the client instance also includes a new interaction section in case the AS needs
to interact with the RO again to gather additional authorization. Note that the client instance's
nonce and callback are different from the initial request. Since the original callback was
already used in the initial exchange, and the callback is intended for one-time-use, a new one
needs to be included in order to use the callback again.

\[\[ [See issue #97](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/97) \]\]

~~~
PATCH /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            "read", "write"
        ]
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return/654321",
            "nonce": "K82FX4T4LKLTI25DQFZC"
        }
    }
}
~~~

From here, the AS can determine that the client instance is asking for more than it was previously granted,
but since the client instance has also provided a mechanism to interact with the RO, the AS can use that
to gather the additional consent. The protocol continues as it would with a new request.
Since the old access tokens are good for a subset of the rights requested here, the 
AS might decide to not revoke them. However, any access tokens granted after this update
process are new access tokens and do not modify the rights of existing access tokens.

## Canceling a Grant Request {#continue-delete}

If the client instance wishes to cancel an ongoing grant request, it makes an
HTTP DELETE request to the continuation URI. 

~~~
DELETE /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...
~~~

If the request is successfully cancelled, the AS responds with an HTTP 202.
The AS SHOULD revoke all associated access tokens.

# Token Management {#token-management}

If an access token response includes the "manage" parameter as
described in {{response-token-single}}, the client instance MAY call
this URL to manage the access token with any of the actions defined in
the following sections. Other actions are undefined by this
specification.

The access token being managed acts as the access element for its own
management API. The client instance MUST present proof of an appropriate key
along with the access token.

If the token is sender-constrained (i.e., not a bearer token), it
MUST be sent [with the appropriate binding for the access token](#use-access-token). 

If the token is a bearer token, the client instance MUST present proof of the
same [key identified in the initial request](#request-client) as described in {{binding-keys}}.

The AS MUST validate the proof and assure that it is associated with
either the token itself or the client instance the token was issued to, as
appropriate for the token's presentation type.

## Rotating the Access Token {#rotate-access-token}

The client instance makes an HTTP POST to the token management URI, sending
the access token in the appropriate header and signing the request
with the appropriate key. 

~~~
POST /token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L HTTP/1.1
Host: server.example.com
Authorization: GNAP OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0
Detached-JWS: eyj0....
~~~

The AS validates that the token presented is associated with the management
URL, that the AS issued the token to the given client instance, and that
the presented key is appropriate to the token. 

If the access token has expired, the AS SHOULD honor the rotation request to 
the token management URL since it is likely that the client instance is attempting to
refresh the expired token. To support this, the AS MAY apply different lifetimes for
the use of the token in management vs. its use at an RS. An AS MUST NOT
honor a rotation request for an access token that has been revoked, either by
the AS or by the client instance through the [token management URI](#revoke-access-token).

If the token is validated and the key is appropriate for the
request, the AS MUST invalidate the current access token associated
with this URL, if possible, and return a new access token response as
described in {{response-token-single}}, unless the `multi_token` flag
is specified in the request. The value of the
access token MUST NOT be the same as the current value of the access
token used to access the management API. The response MAY include an
updated access token management URL as well, and if so, the client instance
MUST use this new URL to manage the new access token.
\[\[ [See issue #101](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/101) \]\]

\[\[ [See issue #102](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/102) \]\]

~~~
{
    "access_token": {
        "value": "FP6A8H6HY37MH13CK76LBZ6Y1UADG6VEUPEER5H2",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
        "access": [
            {
                "type": "photo-api",
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            },
            "read", "dolphin-metadata"
        ]
    }
}
~~~

\[\[ [See issue #103](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/103) \]\]

## Revoking the Access Token {#revoke-access-token}

If the client instance wishes to revoke the access token proactively, such as when
a user indicates to the client instance that they no longer wish for it to have
access or the client instance application detects that it is being uninstalled,
the client instance can use the token management URI to indicate to the AS that
the AS should invalidate the access token for all purposes.

The client instance makes an HTTP DELETE request to the token management
URI, presenting the access token and signing the request with
the appropriate key.

~~~
DELETE /token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L HTTP/1.1
Host: server.example.com
Authorization: GNAP OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0
Detached-JWS: eyj0....
~~~

If the key presented is associated with the token (or the client instance, in
the case of a bearer token), the AS MUST invalidate the access token, if
possible, and return an HTTP 204 response code.

~~~
204 No Content
~~~

Though the AS MAY revoke an access token at any time for
any reason, the token management function is specifically for the client instance's use.
If the access token has already expired or has been revoked through other
means, the AS SHOULD honor the revocation request to 
the token management URL as valid, since the end result is still the token
not being usable.


# Securing Requests from the Client Instance {#secure-requests}

In GNAP, the client instance secures its requests to the AS and RS by presenting an access
token, presenting proof of a key that it possesses, or both an access token and
key proof together.

- When an access token is used with a key proof, this is a bound token request. This type of
    request is used for calls to the RS as well as the AS during negotiation.
- When a key proof is used with no access token, this is a non-authorized signed request. This
    type of request is used for calls to the AS to initiate a negotiation.
- When an access token is used with no key proof, this is a bearer token request. This type of
    request is used only for calls to the RS, and only with access tokens that are
    not bound to any key as described in {{response-token-single}}.
- When neither an access token nor key proof are used, this is an unsecured request. This 
    type of used only for calls to the RS during a discovery phase as
    described in {{rs-request-without-token}}.

## Key Formats {#key-format}

Several different places in GNAP require the presentation of key material 
by value. Proof of this key material MUST be bound to a request, the nature of which varies with
the location in the protocol the key is used. For a key used as part of a client instance's initial request
in {{request-client}}, the key value is the client instance's public key, and
proof of that key MUST be presented in that request. For a key used as part of an
access token response in {{response-token-single}}, the proof of that key MUST
be used when presenting the access token.

A key presented by value MUST be a public key in at least one
supported format. If a key is sent in multiple
formats, all the key format values MUST be equivalent. Note that
while most formats present the full value of the public key, some
formats present a value cryptographically derived from the public key.

proof (string)
: The form of proof that the client instance will use when
    presenting the key. The valid values of this field and
    the processing requirements for each are detailed in 
    {{binding-keys}}. The `proof` field is REQUIRED.

jwk (object)
: Value of the public key as a JSON Web Key {{RFC7517}}. The object MUST
            contain an "alg" field which is used to validate the signature.
            The object MUST contain the "kid" field to identify the key.

cert (string)
: PEM serialized value of the certificate used to
            sign the request, with optional internal whitespace per {{RFC7468}}. The 
            PEM header and footer are optionally removed. 

cert#S256 (string)
: The certificate thumbprint calculated as
            per [OAuth-MTLS](#RFC8705) in base64 URL
            encoding. Note that this format does not include
            the full public key.

Additional key formats are defined in [a registry TBD](#IANA).

This non-normative example shows a single key presented in multiple
formats. This key is intended to be used with the [detached JWS](#detached-jws)
proofing mechanism, as indicated by the `proof` field.

~~~
    "key": {
        "proof": "jwsd",
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_JtffXyaSx8xY..."
        },
        "cert": "MIIEHDCCAwSgAwIBAgIBATANBgkqhkiG9w0BAQsFA..."
    }
~~~

### Key References {#key-reference}

Keys in GNAP can also be passed by reference such that the party receiving
the reference will be able to determine the appropriate keying material for
use in that part of the protocol. 

~~~
    "key": "S-P4XJQ_RYJCRTSU1.63N3E"
~~~

Keys referenced in this manner MAY be shared symmetric keys. The key reference
MUST NOT contain any unencrypted private or shared symmetric key information.

Keys referenced in this manner MUST be bound to a single proofing mechanism.

The means of dereferencing this value are out of scope for this specification.

## Presenting Access Tokens {#use-access-token}

The method the client instance uses to send an access token depends on whether
the token is bound to a key, and if so which proofing method is associated
with the key. This information is conveyed in the
`key` and `proof` parameters in [the access token response](#response-token-single).

If the `key` value is the boolean `false`, the access token is a bearer token
sent using the HTTP Header method defined in {{RFC6750}}.

~~~
Authorization: Bearer OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0
~~~

The form parameter and query parameter methods of {{RFC6750}} MUST NOT
be used.

If the `key` value is the boolean `true`, the access token MUST be sent
using the same key and proofing mechanism that the client instance used
in its initial request (or its most recent rotation).

If the `key` value is an object as described in {{key-format}}, the value of the `proof` field within
the key indicates the particular proofing mechanism to use.
The access token is sent using the HTTP authorization scheme "GNAP" along with 
a key proof as described in {{binding-keys}} for the key bound to the
access token. For example, a "jwsd"-bound access token is sent as
follows:

~~~
Authorization: GNAP OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0
Detached-JWS: eyj0....
~~~


\[\[ [See issue #104](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/104) \]\]

## Proving Possession of a Key with a Request {#binding-keys}

Any keys presented by the client instance to the AS or RS MUST be validated as
part of the request in which they are presented. The type of binding
used is indicated by the proof parameter of the key object in {{key-format}}. 
Values defined by this specification are as follows:


jwsd
: A detached JWS signature header

jws
: Attached JWS payload

mtls
: Mutual TLS certificate verification

dpop
: OAuth Demonstration of Proof-of-Possession key proof header

httpsig
: HTTP Signing signature header

oauthpop
: OAuth PoP key proof authentication header


Additional proofing methods are defined by [a registry TBD](#IANA).

All key binding methods used by this specification MUST cover all relevant portions
of the request, including anything that would change the nature of the request, to allow
for secure validation of the request by the AS. Relevant aspects include
the URI being called, the HTTP method being used, any relevant HTTP headers and
values, and the HTTP message body itself. The recipient of the signed message
MUST validate all components of the signed message to ensure that nothing
has been tampered with or substituted in a way that would change the nature of
the request.

When a key proofing mechanism is bound to an access token, the access token MUST be covered 
by the signature method of the proofing mechanism.

When used for delegation in GNAP, these key binding mechanisms allow
the AS to ensure that the keys presented by the client instance in the initial request are in 
control of the party calling any follow-up or continuation requests. To facilitate 
this requirement, the [continuation response](#response-continue) includes
an access token bound to the [client instance's key](#request-client), and that key (or its most recent rotation)
MUST be proved in all continuation requests
{{continue-request}}. Token management requests {{token-management}} are similarly bound
to either the access token's own key or, in the case of bearer tokens, the client instance's key.

\[\[ [See issue #105](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/105) \]\]

### Detached JWS {#detached-jws}

This method is indicated by `jwsd` in the
`proof` field. A JWS {{RFC7515}} signature object is created as follows:

The header of the JWS MUST contain the
`kid` field of the key bound to this client instance for this request. The JWS header
MUST contain an `alg` field appropriate for the key identified by kid
and MUST NOT be `none`.  The `b64` field MUST be set to `false` and the
`crit` field MUST contain at least `b64` as specified in {{RFC7797}}

To protect the request, the JWS header MUST contain the following
additional fields.

htm (string)
: The HTTP Method used to make this request, as an uppercase ASCII string.

htu (string)
: The HTTP URI used for this request, including all path and query components.

ts (integer)
: A timestamp of the request in integer seconds

at_hash (string)
: When to bind a request to an access token, the access token hash value. Its value is the 
    base64url encoding of the left-most half of the hash of the octets of the ASCII representation of the 
    `access_token` value, where the hash algorithm used is the hash algorithm used in the `alg` 
    header parameter of the JWS's JOSE Header. For instance, if the `alg` is `RS256`, hash the `access_token` 
    value with SHA-256, then take the left-most 128 bits and base64url encode them. 

The payload of the JWS object is the serialized body of the request, and
the object is signed according to detached JWS {{RFC7797}}. 

The client instance presents the signature in the Detached-JWS HTTP Header
field. 

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: eyJiNjQiOmZhbHNlLCJhbGciOiJSUzI1NiIsImtpZCI6Inh5ei0xIn0.
  .Y287HMtaY0EegEjoTd_04a4GC6qV48GgVbGKOhHdJnDtD0VuUlVjLfwne8AuUY3U7e8
  9zUWwXLnAYK_BiS84M8EsrFvmv8yDLWzqveeIpcN5_ysveQnYt9Dqi32w6IOtAywkNUD
  ZeJEdc3z5s9Ei8qrYFN2fxcu28YS4e8e_cHTK57003WJu-wFn2TJUmAbHuqvUsyTb-nz
  YOKxuCKlqQItJF7E-cwSb_xULu-3f77BEU_vGbNYo5ZBa2B7UHO-kWNMSgbW2yeNNLbL
  C18Kv80GF22Y7SbZt0e2TwnR2Aa2zksuUbntQ5c7a1-gxtnXzuIKa34OekrnyqE1hmVW
  peQ
 
{
    "access_token": {
        "access": [
            "dolphin-metadata"
        ]
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.foo",
            "nonce": "VJLO6A4CAYLBXHTR0KRO"
        }
    },
    "client": {
      "proof": "jwsd",
      "key": {
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_JtffXyaSx8
xYJCNaOKNJn_Oz0YhdHbXTeWO5AoyspDWJbN5w_7bdWDxgpD-y6jnD1u9YhBOCWObNPF
vpkTM8LC7SdXGRKx2k8Me2r_GssYlyRpqvpBlY5-ejCywKRBfctRcnhTTGNztbbDBUyD
SWmFMVCHe5mXT4cL0BwrZC6S-uu-LAx06aKwQOPwYOGOslK8WPm1yGdkaA1uF_FpS6LS
63WYPHi_Ap2B7_8Wbw4ttzbMS_doJvuDagW8A1Ip3fXFAHtRAcKw7rdI4_Xln66hJxFe
kpdfWdiPQddQ6Y1cK2U3obvUg7w"
        }
      }
      "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
      },
    }
}
~~~

If the request being made does not have a message body, such as
an HTTP GET, OPTIONS, or DELETE method, the JWS signature is
calculated over an empty payload.

When the server (AS or RS) receives the Detached-JWS header, it MUST parse its
contents as a detached JWS object. The HTTP Body is used as the
payload for purposes of validating the JWS, with no
transformations.

### Attached JWS {#attached-jws}

This method is indicated by `jws` in the
`proof` field. A JWS {{RFC7515}} signature object is created as follows:

The header of the JWS MUST contain the
`kid` field of the key bound to this client instance for this request. The JWS header
MUST contain an `alg` field appropriate for the key identified by `kid`
and MUST NOT be `none`.

To protect the request, the JWS header MUST contain the following
additional fields.

htm (string)
: The HTTP Method used to make this request, as an uppercase ASCII string.

htu (string)
: The HTTP URI used for this request, including all path and query components.

ts (integer)
: A timestamp of the request in integer seconds

at_hash (string)
: When to bind a request to an access token, the access token hash value. Its value is the 
    base64url encoding of the left-most half of the hash of the octets of the ASCII representation of the 
    `access_token` value, where the hash algorithm used is the hash algorithm used in the `alg` 
    header parameter of the JWS's JOSE Header. For instance, if the `alg` is `RS256`, hash the `access_token` 
    value with SHA-256, then take the left-most 128 bits and base64url encode them. 

The payload of the JWS object is the JSON serialized body of the request, and
the object is signed according to JWS and serialized into compact form {{RFC7515}}. 

The client instance presents the JWS as the body of the request along with a
content type of `application/jose`. The AS
MUST extract the payload of the JWS and treat it as the request body
for further processing.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/jose
 
eyJhbGciOiJSUzI1NiIsImtpZCI6IktBZ05wV2JSeXk5T
WYycmlrbDQ5OExUaE1ydmtiWldIVlNRT0JDNFZIVTQiLC
JodG0iOiJwb3N0IiwiaHR1IjoiL3R4IiwidHMiOjE2MDM
4MDA3ODN9.eyJjYXBhYmlsaXRpZXMiOltdLCJjbGllbnQ
iOnsia2V5Ijp7Imp3ayI6eyJrdHkiOiJSU0EiLCJlIjoi
QVFBQiIsImtpZCI6IktBZ05wV2JSeXk5TWYycmlrbDQ5O
ExUaE1ydmtiWldIVlNRT0JDNFZIVTQiLCJuIjoibGxXbU
hGOFhBMktOTGRteE9QM2t4RDlPWTc2cDBTcjM3amZoejk
0YTkzeG0yRk5xb1NQY1JaQVBkMGxxRFM4TjNVaWE1M2RC
MjNaNTlPd1k0YnBNX1ZmOEdKdnZwdExXbnhvMVB5aG1Qc
i1lY2RTQ1JRZFRjX1pjTUY0aFJWNDhxcWx2dUQwbXF0Y0
RiSWtTQkR2Y2NKbVpId2ZUcERIaW5UOHR0dmNWUDhWa0F
NQXE0a1ZhenhPcE1vSVJzb3lFcF9lQ2U1cFN3cUhvMGRh
Q1dOS1ItRXBLbTZOaU90ZWRGNE91bXQ4TkxLVFZqZllnR
khlQkRkQ2JyckVUZDR2Qk13RHRBbmpQcjNDVkN3d3gyYk
FRVDZTbHhGSjNmajJoaHlJcHE3cGM4clppYjVqTnlYS3d
mQnVrVFZZWm96a3NodC1Mb2h5QVNhS3BZVHA4THROWi13
In0sInByb29mIjoiandzIn0sIm5hbWUiOiJNeUZpcnN0Q
2xpZW50IiwidXJpIjoiaHR0cDovL2xvY2FsaG9zdC9jbG
llbnQvY2xpZW50SUQifSwiaW50ZXJhY3QiOnsic3RhcnQ
iOlsicmVkaXJlY3QiXSwiZmluaXNoIjp7Im1ldGhvZCI6
InJlZGlyZWN0Iiwibm9uY2UiOiJkOTAyMTM4ODRiODQwO
TIwNTM4YjVjNTEiLCJ1cmkiOiJodHRwOi8vbG9jYWxob3
N0L2NsaWVudC9yZXF1ZXN0LWRvbmUifX0sImFjY2Vzc19
0b2tlbiI6eyJhY2Nlc3MiOlt7ImFjdGlvbnMiOlsicmVh
ZCIsInByaW50Il0sImxvY2F0aW9ucyI6WyJodHRwOi8vb
G9jYWxob3N0L3Bob3RvcyJdLCJ0eXBlIjoicGhvdG8tYX
BpIn1dfSwic3ViamVjdCI6eyJzdWJfaWRzIjpbImlzc19
zdWIiLCJlbWFpbCJdfX0.LUyZ8_fERmxbYARq8kBYMwzc
d8GnCAKAlo2ZSYLRRNAYWPrp2XGLJOvg97WK1idf_LB08
OJmLVsCXxCvn9mgaAkYNL_ZjHcusBvY1mNo0E1sdTEr31
CVKfC-6WrZCscb8YqE4Ayhh0Te8kzSng3OkLdy7xN4xeK
uHzpF7yGsM52JZ0cBcTo6WrYEfGdr08AWQJ59ht72n3jT
smYNy9A6I4Wrvfgj3TNxmwYojpBAicfjnzA1UVcNm9F_x
iSz1_y2tdH7j5rVqBMQife-k9Ewk95vr3lurthenliYSN
iUinVfoW1ybnaIBcTtP1_YCxg_h1y-B5uZEvYNGCuoCqa
6IQ
~~~

This example's JWS header decodes to:

~~~
{
  "alg": "RS256",
  "kid": "KAgNpWbRyy9Mf2rikl498LThMrvkbZWHVSQOBC4VHU4",
  "htm": "POST",
  "htu": "https://server.example.com/tx",
  "ts": 1603800783
}
~~~

And the JWS body decodes to:

~~~
{
  "capabilities": [],
  "client": {
    "key": {
      "jwk": {
        "kty": "RSA",
        "e": "AQAB",
        "kid": "KAgNpWbRyy9Mf2rikl498LThMrvkbZWHVSQOBC4VHU4",
        "n": "llWmHF8XA2KNLdmxOP3kxD9OY76p0Sr37jfhz94a93xm2FNqoSPc
        RZAPd0lqDS8N3Uia53dB23Z59OwY4bpM_Vf8GJvvptLWnxo1PyhmPr-ecd
        SCRQdTc_ZcMF4hRV48qqlvuD0mqtcDbIkSBDvccJmZHwfTpDHinT8ttvcV
        P8VkAMAq4kVazxOpMoIRsoyEp_eCe5pSwqHo0daCWNKR-EpKm6NiOtedF4
        Oumt8NLKTVjfYgFHeBDdCbrrETd4vBMwDtAnjPr3CVCwwx2bAQT6SlxFJ3
        fj2hhyIpq7pc8rZib5jNyXKwfBukTVYZozksht-LohyASaKpYTp8LtNZ-w"
      },
      "proof": "jws"
    },
    "name": "My First Client",
    "uri": "http://localhost/client/clientID"
  },
  "interact": {
    "start": ["redirect"],
    "finish": {
      "method": "redirect",
      "nonce": "d90213884b840920538b5c51",
      "uri": "http://localhost/client/request-done"
    }
  },
  "access_token": {
    "access": [
      {
        "actions": [
          "read",
          "print"
        ],
        "locations": [
          "http://localhost/photos"
        ],
        "type": "photo-api"
      }
    ]
  }
  "subject": {
    "sub_ids": [
      "iss_sub",
      "email"
    ]
  }
}
~~~


If the request being made does not have a message body, such as
an HTTP GET, OPTIONS, or DELETE method, the JWS signature is
calculated over an empty payload and passed in the `Detached-JWS`
header as described in {{detached-jws}}.

\[\[ [See issue #109](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/109) \]\]

### Mutual TLS {#mtls}

This method is indicated by `mtls` in the
`proof` field. The client instance presents its TLS client
certificate during TLS negotiation with the server (either AS or RS).
The AS or RS takes the thumbprint of the TLS client certificate presented
during mutual TLS negotiation and compares that thumbprint to the
thumbprint presented by the client instance application as described in 
{{RFC8705}} section 3.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
SSL_CLIENT_CERT: MIIEHDCCAwSgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBmjE3MDUGA1UEAwwuQmVz
 cG9rZSBFbmdpbmVlcmluZyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eTELMAkG
 A1UECAwCTUExCzAJBgNVBAYTAlVTMRkwFwYJKoZIhvcNAQkBFgpjYUBic3BrLmlv
 MRwwGgYDVQQKDBNCZXNwb2tlIEVuZ2luZWVyaW5nMQwwCgYDVQQLDANNVEkwHhcN
 MTkwNDEwMjE0MDI5WhcNMjQwNDA4MjE0MDI5WjB8MRIwEAYDVQQDDAlsb2NhbGhv
 c3QxCzAJBgNVBAgMAk1BMQswCQYDVQQGEwJVUzEgMB4GCSqGSIb3DQEJARYRdGxz
 Y2xpZW50QGJzcGsuaW8xHDAaBgNVBAoME0Jlc3Bva2UgRW5naW5lZXJpbmcxDDAK
 BgNVBAsMA01USTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMmaXQHb
 s/wc1RpsQ6Orzf6rN+q2ijaZbQxD8oi+XaaN0P/gnE13JqQduvdq77OmJ4bQLokq
 sd0BexnI07Njsl8nkDDYpe8rNve5TjyUDCfbwgS7U1CluYenXmNQbaYNDOmCdHww
 UjV4kKREg6DGAx22Oq7+VHPTeeFgyw4kQgWRSfDENWY3KUXJlb/vKR6lQ+aOJytk
 vj8kVZQtWupPbvwoJe0na/ISNAOhL74w20DWWoDKoNltXsEtflNljVoi5nqsmZQc
 jfjt6LO0T7O1OX3Cwu2xWx8KZ3n/2ocuRqKEJHqUGfeDtuQNt6Jz79v/OTr8puLW
 aD+uyk6NbtGjoQsCAwEAAaOBiTCBhjAJBgNVHRMEAjAAMAsGA1UdDwQEAwIF4DBs
 BgNVHREEZTBjgglsb2NhbGhvc3SCD3Rsc2NsaWVudC5sb2NhbIcEwKgBBIERdGxz
 Y2xpZW50QGJzcGsuaW+GF2h0dHA6Ly90bHNjbGllbnQubG9jYWwvhhNzc2g6dGxz
 Y2xpZW50LmxvY2FsMA0GCSqGSIb3DQEBCwUAA4IBAQCKKv8WlLrT4Z5NazaUrYtl
 TF+2v0tvZBQ7qzJQjlOqAcvxry/d2zyhiRCRS/v318YCJBEv4Iq2W3I3JMMyAYEe
 2573HzT7rH3xQP12yZyRQnetdiVM1Z1KaXwfrPDLs72hUeELtxIcfZ0M085jLboX
 hufHI6kqm3NCyCCTihe2ck5RmCc5l2KBO/vAHF0ihhFOOOby1v6qbPHQcxAU6rEb
 907/p6BW/LV1NCgYB1QtFSfGxowqb9FRIMD2kvMSmO0EMxgwZ6k6spa+jk0IsI3k
 lwLW9b+Tfn/daUbIDctxeJneq2anQyU2znBgQl6KILDSF4eaOqlBut/KNZHHazJh
 
{
    "access_token": {
        "access": [
            "dolphin-metadata"
        ]
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.foo",
            "nonce": "VJLO6A4CAYLBXHTR0KRO"
        }
    },
    "client": {
      "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
      },
      "key": {
        "proof": "mtls",
        "cert": "MIIEHDCCAwSgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBmjE3
MDUGA1UEAwwuQmVzcG9rZSBFbmdpbmVlcmluZyBSb290IENlcnRpZmljYXRlIEF1d
Ghvcml0eTELMAkGA1UECAwCTUExCzAJBgNVBAYTAlVTMRkwFwYJKoZIhvcNAQkBFg
pjYUBic3BrLmlvMRwwGgYDVQQKDBNCZXNwb2tlIEVuZ2luZWVyaW5nMQwwCgYDVQQ
LDANNVEkwHhcNMTkwNDEwMjE0MDI5WhcNMjQwNDA4MjE0MDI5WjB8MRIwEAYDVQQD
DAlsb2NhbGhvc3QxCzAJBgNVBAgMAk1BMQswCQYDVQQGEwJVUzEgMB4GCSqGSIb3D
QEJARYRdGxzY2xpZW50QGJzcGsuaW8xHDAaBgNVBAoME0Jlc3Bva2UgRW5naW5lZX
JpbmcxDDAKBgNVBAsMA01USTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggE
BAMmaXQHbs/wc1RpsQ6Orzf6rN+q2ijaZbQxD8oi+XaaN0P/gnE13JqQduvdq77Om
J4bQLokqsd0BexnI07Njsl8nkDDYpe8rNve5TjyUDCfbwgS7U1CluYenXmNQbaYND
OmCdHwwUjV4kKREg6DGAx22Oq7+VHPTeeFgyw4kQgWRSfDENWY3KUXJlb/vKR6lQ+
aOJytkvj8kVZQtWupPbvwoJe0na/ISNAOhL74w20DWWoDKoNltXsEtflNljVoi5nq
smZQcjfjt6LO0T7O1OX3Cwu2xWx8KZ3n/2ocuRqKEJHqUGfeDtuQNt6Jz79v/OTr8
puLWaD+uyk6NbtGjoQsCAwEAAaOBiTCBhjAJBgNVHRMEAjAAMAsGA1UdDwQEAwIF4
DBsBgNVHREEZTBjgglsb2NhbGhvc3SCD3Rsc2NsaWVudC5sb2NhbIcEwKgBBIERdG
xzY2xpZW50QGJzcGsuaW+GF2h0dHA6Ly90bHNjbGllbnQubG9jYWwvhhNzc2g6dGx
zY2xpZW50LmxvY2FsMA0GCSqGSIb3DQEBCwUAA4IBAQCKKv8WlLrT4Z5NazaUrYtl
TF+2v0tvZBQ7qzJQjlOqAcvxry/d2zyhiRCRS/v318YCJBEv4Iq2W3I3JMMyAYEe2
573HzT7rH3xQP12yZyRQnetdiVM1Z1KaXwfrPDLs72hUeELtxIcfZ0M085jLboXhu
fHI6kqm3NCyCCTihe2ck5RmCc5l2KBO/vAHF0ihhFOOOby1v6qbPHQcxAU6rEb907
/p6BW/LV1NCgYB1QtFSfGxowqb9FRIMD2kvMSmO0EMxgwZ6k6spa+jk0IsI3klwLW
9b+Tfn/daUbIDctxeJneq2anQyU2znBgQl6KILDSF4eaOqlBut/KNZHHazJh"
    }
}

~~~

\[\[ [See issue #110](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/110) \]\]

### Demonstration of Proof-of-Possession (DPoP) {#dpop-binding}

This method is indicated by `dpop` in the
`proof` field. The client instance creates a Demonstration of Proof-of-Possession
signature header as described in {{I-D.ietf-oauth-dpop}}
section 2. In addition to the required fields, the DPoP body MUST also
contain a digest of the request body:

digest (string)
: Digest of the request body as the value of the Digest 
    header defined in {{RFC3230}}.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
DPoP: eyJ0eXAiOiJkcG9wK2p3dCIsImFsZyI6IlJTMjU2IiwiandrIjp7Imt0eSI6Il
JTQSIsImUiOiJBUUFCIiwia2lkIjoieHl6LWNsaWVudCIsImFsZyI6IlJTMjU2Iiwibi
I6Inp3Q1RfM2J4LWdsYmJIcmhlWXBZcFJXaVk5SS1uRWFNUnBablJySWpDczZiX2VteV
RrQmtEREVqU3lzaTM4T0M3M2hqMS1XZ3hjUGRLTkdaeUlvSDNRWmVuMU1LeXloUXBMSk
cxLW9MTkxxbTdwWFh0ZFl6U2RDOU8zLW9peXk4eWtPNFlVeU5aclJSZlBjaWhkUUNiT1
9PQzhRdWdtZzlyZ05ET1NxcHBkYU5lYXMxb3Y5UHhZdnhxcnoxLThIYTdna0QwMFlFQ1
hIYUIwNXVNYVVhZEhxLU9fV0l2WVhpY2c2STVqNlM0NFZOVTY1VkJ3dS1BbHluVHhRZE
1BV1AzYll4VlZ5NnAzLTdlVEpva3ZqWVRGcWdEVkRaOGxVWGJyNXlDVG5SaG5oSmd2Zj
NWakRfbWFsTmU4LXRPcUs1T1NEbEhUeTZnRDlOcWRHQ20tUG0zUSJ9fQ.eyJodHRwX21
ldGhvZCI6IlBPU1QiLCJodHRwX3VyaSI6Imh0dHA6XC9cL2hvc3QuZG9ja2VyLmludGV
ybmFsOjk4MzRcL2FwaVwvYXNcL3RyYW5zYWN0aW9uIiwiaWF0IjoxNTcyNjQyNjEzLCJ
qdGkiOiJIam9IcmpnbTJ5QjR4N2pBNXl5RyJ9.aUhftvfw2NoW3M7durkopReTvONng1
fOzbWjAlKNSLL0qIwDgfG39XUyNvwQ23OBIwe6IuvTQ2UBBPklPAfJhDTKd8KHEAfidN
B-LzUOzhDetLg30yLFzIpcEBMLCjb0TEsmXadvxuNkEzFRL-Q-QCg0AXSF1h57eAqZV8
SYF4CQK9OUV6fIWwxLDd3cVTx83MgyCNnvFlG_HDyim1Xx-rxV4ePd1vgDeRubFb6QWj
iKEO7vj1APv32dsux67gZYiUpjm0wEZprjlG0a07R984KLeK1XPjXgViEwEdlirUmpVy
T9tyEYqGrTfm5uautELgMls9sgSyE929woZ59elg
 
{
    "access_token": {
        "access": [
            "dolphin-metadata"
        ]
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.foo",
            "nonce": "VJLO6A4CAYLBXHTR0KRO"
        }
    },
    "client": {
      "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
      },
      "proof": "dpop",
      "key": {
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_JtffXyaSx8xYJ
CCNaOKNJn_Oz0YhdHbXTeWO5AoyspDWJbN5w_7bdWDxgpD-y6jnD1u9YhBOCWObNPFvpkTM
8LC7SdXGRKx2k8Me2r_GssYlyRpqvpBlY5-ejCywKRBfctRcnhTTGNztbbDBUyDSWmFMVCH
e5mXT4cL0BwrZC6S-uu-LAx06aKwQOPwYOGOslK8WPm1yGdkaA1uF_FpS6LS63WYPHi_Ap2
B7_8Wbw4ttzbMS_doJvuDagW8A1Ip3fXFAHtRAcKw7rdI4_Xln66hJxFekpdfWdiPQddQ6Y
1cK2U3obvUg7w"
        }
      }
    }
}
~~~

### HTTP Message Signing {#httpsig-binding}

This method is indicated by `httpsig` in
the `proof` field. The client instance creates an HTTP
Signature header as described in {{I-D.ietf-httpbis-message-signatures}} section 4. The client instance MUST
calculate and present the Digest header as defined in {{RFC3230}} and include
this header in the signature.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Content-Length: 716
Signature: keyId="xyz-client", algorithm="rsa-sha256",
 headers="(request-target) digest content-length",
 signature="TkehmgK7GD/z4jGkmcHS67cjVRgm3zVQNlNrrXW32Wv7d
u0VNEIVI/dMhe0WlHC93NP3ms91i2WOW5r5B6qow6TNx/82/6W84p5jqF
YuYfTkKYZ69GbfqXkYV9gaT++dl5kvZQjVk+KZT1dzpAzv8hdk9nO87Xi
rj7qe2mdAGE1LLc3YvXwNxuCQh82sa5rXHqtNT1077fiDvSVYeced0UEm
rWwErVgr7sijtbTohC4FJLuJ0nG/KJUcIG/FTchW9rd6dHoBnY43+3Dzj
CIthXpdH5u4VX3TBe6GJDO6Mkzc6vB+67OWzPwhYTplUiFFV6UZCsDEeu
Sa/Ue1yLEAMg=="]}
Digest: SHA=oZz2O3kg5SEFAhmr0xEBbc4jEfo=
 
{
    "access_token": {
        "access": [
            "dolphin-metadata"
        ]
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "push",
            "uri": "https://client.foo",
            "nonce": "VJLO6A4CAYLBXHTR0KRO"
        }
    },
    "client": {
      "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
      },
      "proof": "httpsig",
      "key": {
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_J
tffXyaSx8xYJCCNaOKNJn_Oz0YhdHbXTeWO5AoyspDWJbN5w_7bdWDxgpD-
y6jnD1u9YhBOCWObNPFvpkTM8LC7SdXGRKx2k8Me2r_GssYlyRpqvpBlY5-
ejCywKRBfctRcnhTTGNztbbDBUyDSWmFMVCHe5mXT4cL0BwrZC6S-uu-LAx
06aKwQOPwYOGOslK8WPm1yGdkaA1uF_FpS6LS63WYPHi_Ap2B7_8Wbw4ttz
bMS_doJvuDagW8A1Ip3fXFAHtRAcKw7rdI4_Xln66hJxFekpdfWdiPQddQ6
Y1cK2U3obvUg7w"
        }
      }
    }
}
~~~

When used to present an access token as in {{use-access-token}},
the Authorization header MUST be included in the signature.

### OAuth Proof of Possession (PoP) {#oauth-pop-binding}

This method is indicated by `oauthpop` in
the `proof` field. The client instance creates an HTTP
Authorization PoP header as described in {{I-D.ietf-oauth-signed-http-request}} section 4, with the
following additional requirements:

- The `at` (access token) field MUST be omitted
            unless this method is being used in conjunction with
            an access token as in {{use-access-token}}.
            \[\[ [See issue #112](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/112) \]\]

- The `b` (body hash) field MUST be calculated and supplied,
    unless there is no entity body (such as a GET, OPTIONS, or
    DELETE request).

- All components of the URL MUST be calculated and supplied

- The m (method) field MUST be supplied

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
PoP: eyJhbGciOiJSUzI1NiIsImp3ayI6eyJrdHkiOiJSU0EiLCJlIjoi
QVFBQiIsImtpZCI6Inh5ei1jbGllbnQiLCJhbGciOiJSUzI1NiIsIm4iO
iJ6d0NUXzNieC1nbGJiSHJoZVlwWXBSV2lZOUktbkVhTVJwWm5ScklqQ3
M2Yl9lbXlUa0JrRERFalN5c2kzOE9DNzNoajEtV2d4Y1BkS05HWnlJb0g
zUVplbjFNS3l5aFFwTEpHMS1vTE5McW03cFhYdGRZelNkQzlPMy1vaXl5
OHlrTzRZVXlOWnJSUmZQY2loZFFDYk9fT0M4UXVnbWc5cmdORE9TcXBwZ
GFOZWFzMW92OVB4WXZ4cXJ6MS04SGE3Z2tEMDBZRUNYSGFCMDV1TWFVYW
RIcS1PX1dJdllYaWNnNkk1ajZTNDRWTlU2NVZCd3UtQWx5blR4UWRNQVd
QM2JZeFZWeTZwMy03ZVRKb2t2allURnFnRFZEWjhsVVhicjV5Q1RuUmhu
aEpndmYzVmpEX21hbE5lOC10T3FLNU9TRGxIVHk2Z0Q5TnFkR0NtLVBtM
1EifX0.eyJwIjoiXC9hcGlcL2FzXC90cmFuc2FjdGlvbiIsImIiOiJxa0
lPYkdOeERhZVBTZnc3NnFjamtqSXNFRmxDb3g5bTU5NFM0M0RkU0xBIiw
idSI6Imhvc3QuZG9ja2VyLmludGVybmFsIiwiaCI6W1siQWNjZXB0Iiwi
Q29udGVudC1UeXBlIiwiQ29udGVudC1MZW5ndGgiXSwiVjQ2OUhFWGx6S
k9kQTZmQU5oMmpKdFhTd3pjSGRqMUloOGk5M0h3bEVHYyJdLCJtIjoiUE
9TVCIsInRzIjoxNTcyNjQyNjEwfQ.xyQ47qy8bu4fyK1T3Ru1Sway8wp6
5rfAKnTQQU92AUUU07I2iKoBL2tipBcNCC5zLH5j_WUyjlN15oi_lLHym
fPdzihtt8_Jibjfjib5J15UlifakjQ0rHX04tPal9PvcjwnyZHFcKn-So
Y3wsARn-gGwxpzbsPhiKQP70d2eG0CYQMA6rTLslT7GgdQheelhVFW29i
27NcvqtkJmiAG6Swrq4uUgCY3zRotROkJ13qo86t2DXklV-eES4-2dCxf
cWFkzBAr6oC4Qp7HnY_5UT6IWkRJt3efwYprWcYouOVjtRan3kEtWkaWr
G0J4bPVnTI5St9hJYvvh7FE8JirIg
 
{
    "access_token": {
        "access": [
            "dolphin-metadata"
        ]
    },
    "interact": {
        "redirect": true,
        "callback": {
            "method": "redirect",
            "uri": "https://client.foo",
            "nonce": "VJLO6A4CAYLBXHTR0KRO"
        }
    },
    "client": {
      "display": {
        "name": "My Client Display Name",
        "uri": "https://example.net/client"
      },
      "proof": "oauthpop",
      "key": {
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_J
tffXyaSx8xYJCCNaOKNJn_Oz0YhdHbXTeWO5AoyspDWJbN5w_7bdWDxgpD-
y6jnD1u9YhBOCWObNPFvpkTM8LC7SdXGRKx2k8Me2r_GssYlyRpqvpBlY5-
ejCywKRBfctRcnhTTGNztbbDBUyDSWmFMVCHe5mXT4cL0BwrZC6S-uu-LAx
06aKwQOPwYOGOslK8WPm1yGdkaA1uF_FpS6LS63WYPHi_Ap2B7_8Wbw4ttz
bMS_doJvuDagW8A1Ip3fXFAHtRAcKw7rdI4_Xln66hJxFekpdfWdiPQddQ6
Y1cK2U3obvUg7w"
        }
      }
    }
}
~~~

\[\[ [See issue #113](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/113) \]\]

# Resource Access Rights {#resource-access-rights}

GNAP provides a rich structure for describing the protected resources
hosted by RSs and accessed by client software. This structure is used when
the client instance [requests an access token](#request-token) and when
an [access token is returned](#response-token).

The root of this structure is a JSON array. The elements of the JSON
array represent rights of access that are associated with the
the access token. The resulting access is the union of all elements
within the array.

The access associated with the access token is described
using objects that each contain multiple
dimensions of access. Each object contains a REQUIRED `type`
property that determines the type of API that the token is used for.

type (string)
: The type of resource request as a string. This field MAY
      define which other fields are allowed in the request object. 
      This field is REQUIRED.

The value of the `type` field is under the control of the AS. 
This field MUST be compared using an exact byte match of the string
value against known types by the AS.  The AS MUST ensure that there
is no collision between different authorization data types that it
supports.  The AS MUST NOT do any collation or normalization of data
types during comparison. It is RECOMMENDED that designers of general-purpose
APIs use a URI for this field to avoid collisions between multiple
API types protected by a single AS.

While it is expected that many APIs will have its own properties, a set of
common properties are defined here. Specific API implementations
SHOULD NOT re-use these fields with different semantics or syntax. The
available values for these properties are determined by the API
being protected at the RS.

actions (array of strings)
: The types of actions the client instance will take at the RS as an array of strings.
    For example, a client instance asking for a combination of "read" and "write" access.

locations (array of strings)
: The location of the RS as an array of
    strings. These strings are typically URIs identifying the
    location of the RS.

datatypes (array of strings)
: The kinds of data available to the client instance at the RS's API as an
    array of strings. For example, a client instance asking for access to
    raw "image" data and "metadata" at a photograph API.

identifier (string)
: A string identifier indicating a specific resource at the RS.
    For example, a patient identifier for a medical API or
    a bank account number for a financial API.

The following non-normative example is describing three kinds of access (read, write, delete) to each of
two different locations and two different data types (metadata, images) for a single access token 
using the fictitious `photo-api` type definition.

~~~
"access": [
    {
        "type": "photo-api",
        "actions": [
            "read",
            "write",
            "delete"
        ],
        "locations": [
            "https://server.example.net/",
            "https://resource.local/other"
        ],
        "datatypes": [
            "metadata",
            "images"
        ]
    }
]
~~~

The access requested for a given object when using these fields 
is the cross-product of all fields of the object. That is to 
say, the object represents a request for all `action` values listed within the object
to be used at all `locations` values listed within the object for all `datatype`
values listed within the object. Assuming the request above was granted,
the client instance could assume that it
would be able to do a `read` action against the `images` on the first server
as well as a `delete` action on the `metadata` of the second server, or any other
combination of these fields, using the same access token. 

To request a different combination of access, 
such as requesting one `action` against one `location` 
and a different `action` against a different `location`, the 
client instance can include multiple separate objects in the `resources` array.
The following non-normative example uses the same fictitious `photo-api`
type definition to request a single access token with more specifically
targeted access rights by using two discrete objects within the request.

~~~
"access": [
    {
        "type": "photo-api",
        "actions": [
            "read"
        ],
        "locations": [
            "https://server.example.net/"
        ],
        "datatypes": [
            "images"
        ]
    },
    {
        "type": "photo-api",
        "actions": [
            "write",
            "delete"
        ],
        "locations": [
            "https://resource.local/other"
        ],
        "datatypes": [
            "metadata"
        ]
    }
]
~~~

The access requested here is for `read` access to `images` on one server
while simultaneously requesting `write` and `delete` access for `metadata` on a different
server, but importantly without requesting `write` or `delete` access to `images` on the
first server.

It is anticipated that API designers will use a combination
of common fields defined in this specification as well as
fields specific to the API itself. The following non-normative 
example shows the use of both common and API-specific fields as 
part of two different fictitious API `type` values. The first
access request includes the `actions`, `locations`, and `datatypes` 
fields specified here as well as the API-specific `geolocation`
field. The second access request includes the `actions` and
`identifier` fields specified here as well as the API-specific
`currency` field.

~~~
"access": [
    {
        "type": "photo-api",
        "actions": [
            "read",
            "write"
        ],
        "locations": [
            "https://server.example.net/",
            "https://resource.local/other"
        ],
        "datatypes": [
            "metadata",
            "images"
        ],
        "geolocation": [
            { lat: -32.364, lng: 153.207 },
            { lat: -35.364, lng: 158.207 }
        ]
    },
    {
        "type": "financial-transaction",
        "actions": [
            "withdraw"
        ],
        "identifier": "account-14-32-32-3", 
        "currency": "USD"
    }
]
~~~

If this request is approved,
the [resulting access token](#response-token-single)'s access rights will be
the union of the requested types of access for each of the two APIs, just as above.

## Requesting Resources By Reference {#resource-access-reference}

Instead of sending an [object describing the requested resource](#resource-access-rights),
access rights MAY be communicated as a string known to
the AS or RS representing the access being requested. Each string
SHOULD correspond to a specific expanded object representation at
the AS. 

~~~
"access": [
    "read", "dolphin-metadata", "some other thing"
]
~~~

This value is opaque to the client instance and MAY be any
valid JSON string, and therefore could include spaces, unicode
characters, and properly escaped string sequences. However, in some
situations the value is intended to be 
seen and understood by the client software's developer. In such cases, the
API designer choosing any such human-readable strings SHOULD take steps
to ensure the string values are not easily confused by a developer,
such as by limiting the strings to easily disambiguated characters.

This functionality is similar in practice to OAuth 2's `scope` parameter {{RFC6749}}, where a single string
represents the set of access rights requested by the client instance. As such, the reference
string could contain any valid OAuth 2 scope value as in {{example-oauth2}}. Note that the reference
string here is not bound to the same character restrictions as in OAuth 2's `scope` definition.

A single `access` array MAY include both object-type and
string-type resource items. In this non-normative example,
the client instance is requesting access to a `photo-api` and `financial-transaction` API type
as well as the reference values of `read`, `dolphin-metadata`, and `some other thing`.

~~~
"access": [
    {
        "type": "photo-api",
        "actions": [
            "read",
            "write",
            "delete"
        ],
        "locations": [
            "https://server.example.net/",
            "https://resource.local/other"
        ],
        "datatypes": [
            "metadata",
            "images"
        ]
    },
    "read", 
    "dolphin-metadata",
    {
        "type": "financial-transaction",
        "actions": [
            "withdraw"
        ],
        "identifier": "account-14-32-32-3", 
        "currency": "USD"
    },
    "some other thing"
]
~~~

The requested access is the union of all elements of the array, including both objects and 
reference strings.

# Discovery {#discovery}

By design, the protocol minimizes the need for any pre-flight
discovery. To begin a request, the client instance only needs to know the endpoint of
the AS and which keys it will use to sign the request. Everything else
can be negotiated dynamically in the course of the protocol. 

However, the AS can have limits on its allowed functionality. If the
client instance wants to optimize its calls to the AS before making a request, it MAY
send an HTTP OPTIONS request to the grant request endpoint to retrieve the
server's discovery information. The AS MUST respond with a JSON document
containing the following information:


grant_request_endpoint (string)
: REQUIRED. The full URL of the
          AS's grant request endpoint. This MUST match the URL the client instance used to
          make the discovery request.

capabilities (array of strings)
: OPTIONAL. A list of the AS's
          capabilities. The values of this result MAY be used by the client instance in the
          [capabilities section](#request-capabilities) of
          the request.

interaction_methods_supported (array of strings)
: OPTIONAL. A list of the AS's
          interaction methods. The values of this list correspond to the
          possible fields in the [interaction section](#request-interact) of the request.

key_proofs_supported (array of strings)
: OPTIONAL. A list of the AS's supported key
          proofing mechanisms. The values of this list correspond to possible
          values of the `proof` field of the 
          [key section](#key-format) of the request.

sub_ids_supported (array of strings)
: OPTIONAL. A list of the AS's supported
          identifiers. The values of this list correspond to possible values
          of the [subject identifier section](#request-subject) of the request.

assertions_supported (array of strings)
: OPTIONAL. A list of the AS's supported
          assertion formats. The values of this list correspond to possible
          values of the [subject assertion section](#request-subject) of the request.


The information returned from this method is for optimization
purposes only. The AS MAY deny any request, or any portion of a request,
even if it lists a capability as supported. For example, a given client instance
can be registered with the `mtls` key proofing
mechanism, but the AS also returns other proofing methods, then the AS
will deny a request from that client instance using a different proofing
mechanism.


# Resource Servers {#resource-servers}

In some deployments, a resource server will need to be able to call
the AS for a number of functions.

\[\[ [See issue #114](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/114) \]\]

## Introspecting a Token {#introspection}

When the RS receives an access token, it can call the introspection
endpoint at the AS to get token information. 
\[\[ [See issue #115](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/115) \]\]

~~~
+--------+       +------+       +------+
| Client |--(1)->|  RS  |       |  AS  |
|Instance|       |      |--(2)->|      |
|        |       |      |<-(3)--|      |
|        |       |      |       +------+
|        |<-(4)--|      |               
+--------+       +------+               
~~~

1. The client instance calls the RS with its access token.

2. The RS introspects the access token value at the AS.
    The RS signs the request with its own key (not the client instance's
    key or the token's key).

3. The AS validates the token value and the client instance's request
    and returns the introspection response for the token.

4. The RS fulfills the request from the client instance.

The RS signs the request with its own key and sends the access
token as the body of the request.

~~~
POST /introspect HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
}
~~~



The AS responds with a data structure describing the token's
current state and any information the RS would need to validate the
token's presentation, such as its intended proofing mechanism and key
material.

~~~
Content-Type: application/json

{
    "active": true,
    "access": [
        "dolphin-metadata", "some other thing"
    ],
    "client": {
      "key": {
        "proof": "httpsig",
        "jwk": {
                    "kty": "RSA",
                    "e": "AQAB",
                    "kid": "xyz-1",
                    "alg": "RS256",
                    "n": "kOB5rR4Jv0GMeL...."
        }
      }
    }
}
~~~




## Deriving a downstream token {#token-chaining}

Some architectures require an RS to act as a client instance and request a derived access
token for a secondary RS. This internal token is issued in the context
of the incoming access token.

~~~
+--------+       +-------+       +------+       +-------+
| Client |--(1)->|  RS1  |       |  AS  |       |  RS2  |
|Instance|       |       |--(2)->|      |       |       |
|        |       |       |<-(3)--|      |       |       |
|        |       |       |       +------+       |       |
|        |       |       |                      |       |
|        |       |       |-----------(4)------->|       |
|        |       |       |<----------(5)--------|       |
|        |<-(6)--|       |                      |       |
+--------+       +-------+                      +-------+
~~~

1. The client instance calls RS1 with an access token.

2. RS1 presents that token to the AS to get a derived token
    for use at RS2. RS1 indicates that it has no ability
    to interact with the RO.
    RS1 signs its request with its own key, not the token's
    key or the client instance's key.

3. The AS returns a derived token to RS1 for use at RS2.

4. RS1 calls RS2 with the token from (3).

5. RS2 fulfills the call from RS1.

6. RS1 fulfills the call from client instance.


If the RS needs to derive a token from one presented to it, it can
request one from the AS by making a token request as described in
{{request}} and presenting the existing access token's
value in the "existing_access_token" field.

The RS MUST identify itself with its own key and sign the
request.

\[\[ [See issue #116](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/116) \]\]

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            {
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            },
            "dolphin-metadata"
        ]
    },
    "client": "7C7C4AZ9KHRS6X63AJAO",
    "existing_access_token": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0"
}
~~~

The AS responds with a token for the downstream RS2 as described in 
{{response-token}}. 

## Registering a Resource Handle {#rs-register-resource-handle}

If the RS needs to, it can post a set of resources as described in
{{resource-access-rights}} to the AS's resource
registration endpoint.

The RS MUST identify itself with its own key and sign the
request.

~~~
POST /resource HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access": [
        {
            "actions": [
                "read",
                "write",
                "dolphin"
            ],
            "locations": [
                "https://server.example.net/",
                "https://resource.local/other"
            ],
            "datatypes": [
                "metadata",
                "images"
            ]
        },
        "dolphin-metadata"
    ],
    "client": "7C7C4AZ9KHRS6X63AJAO"

}
~~~



The AS responds with a handle appropriate to represent the
resources list that the RS presented.

~~~
Content-Type: application/json

{
    "resource_handle": "FWWIKYBQ6U56NL1"
}
~~~



The RS MAY make this handle available as part of a 
[response](#rs-request-without-token) or as
documentation to developers.

\[\[ [See issue #117](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/117) \]\]

## Requesting Resources With Insufficient Access {#rs-request-without-token}

If the client instance calls an RS without an access token, or with an
invalid access token, the RS MAY respond to the client instance with an
authentication header indicating that GNAP needs to be used
to access the resource. The address of the GNAP
endpoint MUST be sent in the "as_uri" parameter. The RS MAY
additionally return a resource reference that the client instance MAY use in
its [access token request](#request-token). This
resource reference handle SHOULD be sufficient for at least the action
the client instance was attempting to take at the RS. The RS MAY use the [dynamic resource handle request](#rs-register-resource-handle) to register a new resource handle, or use a handle that
has been pre-configured to represent what the AS is protecting. The
content of this handle is opaque to the RS and the client instance.

~~~
WWW-Authenticate: GNAP as_uri=https://server.example/tx,resource=FWWIKYBQ6U56NL1
~~~

The client instance then makes a call to the "as_uri" as described in 
{{request}}, with the value of "resource" as one of the members
of the `access` array {{request-token-single}}. The
client instance MAY request additional resources and other information, and MAY
request multiple access tokens.

\[\[ [See issue #118](https://github.com/ietf-wg-gnap/gnap-core-protocol/issues/118) \]\]

# Acknowledgements {#Acknowledgements}

The editors would like to thank the feedback of the following individuals for their reviews,
implementations, and contributions:
Aaron Parecki,
Annabelle Backman,
Dick Hardt,
Dmitri Zagidulin,
Dmitry Barinov,
Fabien Imbault,
Francis Pouatcha,
George Fletcher,
Haardik Haardik,
Hamid Massaoud,
Jacky Yuan,
Joseph Heenan,
Justin Richer,
Kathleen Moriarty,
Mike Jones,
Mike Varley,
Nat Sakimura,
Takahiko Kawasaki,
Takahiro Tsuchiya.

The editors would also like to thank the GNAP working group design team of
Kathleen Moriarty, Fabien Imbault, Dick Hardt, Mike Jones, and Justin Richer, who incorporated
elements from the XAuth and XYZ proposals to create the first version of this document.

In addition, the editors would like to thank Aaron Parecki and Mike Jones for insights into how
to integrate identity and authentication systems into the core protocol, and Justin Richer and Dick Hardt for
the use cases, diagrams, and insights provided in the XYZ and XAuth proposals that have been
incorporated here. The editors would like to especially thank Mike Varley and the team at SecureKey
for feedback and development of early versions of the XYZ protocol that fed into this standards work.

# IANA Considerations {#IANA}

\[\[ TBD: There are a lot of items in the document that are expandable
through the use of value registries. \]\]


# Security Considerations {#Security}

\[\[ TBD: There are a lot of security considerations to add. \]\]

All requests have to be over TLS or equivalent as per {{BCP195}}. Many handles act as
shared secrets, though they can be combined with a requirement to
provide proof of a key as well.


# Privacy Considerations {#Privacy}

\[\[ TBD: There are a lot of privacy considerations to add. \]\]

Handles are passed between parties and therefore should not contain
any private data.

When user information is passed to the client instance, the AS needs to make
sure that it has the permission to do so.

--- back
   
# Document History {#history}

- -Since 04
    - 

- -04
    - Updated terminology.
    - Refactored key presentation and binding.
    - Refactored "interact" request to group start and end modes.
    - Changed access token request and response syntax.
    - Removed closed issue links.
    - Removed function to read state of grant request by client.
    - Closed issues related to reading and updating access tokens.

- -03
    - Changed "resource client" terminology to separate "client instance" and "client software".
    - Removed OpenID Connect "claims" parameter.
    - Dropped "short URI" redirect.
    - Access token is mandatory for continuation.
    - Removed closed issue links.
    - Editorial fixes.

- -02
    - Moved all "editor's note" items to GitHub Issues.
    - Added JSON types to fields.
    - Changed "GNAP Protocol" to "GNAP".
    - Editorial fixes.

- -01
    - "updated_at" subject info timestamp now in ISO 8601 string format.
    - Editorial fixes.
    - Added Aaron and Fabien as document authors.

- -00 
    - Initial working group draft.

# Component Data Models {#data-models}

While different implementations of this protocol will have different
realizations of all the components and artifacts enumerated here, the
nature of the protocol implies some common structures and elements for
certain components. This appendix seeks to enumerate those common
elements. 

TBD: Client has keys, allowed requested resources, identifier(s),
allowed requested subjects, allowed 

TBD: AS has "grant endpoint", interaction endpoints, store of trusted
client keys, policies

TBD: Token has RO, user, client, resource list, RS list, 


# Example Protocol Flows {#examples}

The protocol defined in this specification provides a number of
features that can be combined to solve many different kinds of
authentication scenarios. This section seeks to show examples of how the
protocol would be applied for different situations.

Some longer fields, particularly cryptographic information, have been
truncated for display purposes in these examples.

## Redirect-Based User Interaction {#example-auth-code}

In this scenario, the user is the RO and has access to a web
browser, and the client instance can take front-channel callbacks on the same
device as the user. This combination is analogous to the OAuth 2
Authorization Code grant type.

The client instance initiates the request to the AS. Here the client instance
identifies itself using its public key.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            {
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            }
        ],
    },
    "client": {
      "key": {
        "proof": "jwsd",
        "jwk": {
            "kty": "RSA",
            "e": "AQAB",
            "kid": "xyz-1",
            "alg": "RS256",
            "n": "kOB5rR4Jv0GMeLaY6_It_r3ORwdf8ci_JtffXyaSx8xY..."
        }
      }
    },
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return/123455",
            "nonce": "LKLTI25DK82FX4T4QFZC"
        }
    }
}
~~~



The AS processes the request and determines that the RO needs to
interact. The AS returns the following response giving the client instance the
information it needs to connect. The AS has also indicated to the
client instance that it can use the given instance identifier to identify itself in
[future requests](#request-instance).

~~~
Content-Type: application/json

{
    "interact": {
       "redirect": "https://server.example.com/interact/4CF492MLVMSW9MKMXKHQ",
       "push": "MBDOFXG4Y5CVJCX821LH"
    }
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue"
    },
    "instance_id": "7C7C4AZ9KHRS6X63AJAO"
}
~~~



The client instance saves the response and redirects the user to the
interaction_url by sending the following HTTP message to the user's
browser.

~~~
HTTP 302 Found
Location: https://server.example.com/interact/4CF492MLVMSW9MKMXKHQ
~~~



The user's browser fetches the AS's interaction URL. The user logs
in, is identified as the RO for the resource being requested, and
approves the request. Since the AS has a callback parameter, the AS
generates the interaction reference, calculates the hash, and
redirects the user back to the client instance with these additional values
added as query parameters.

~~~
HTTP 302 Found
Location: https://client.example.net/return/123455
  ?hash=p28jsq0Y2KK3WS__a42tavNC64ldGTBroywsWxT4md_jZQ1R2HZT8BOWYHcLmObM7XHPAdJzTZMtKBsaraJ64A
  &interact_ref=4IFWWIKYBC2PQ6U56NL1
~~~



The client instance receives this request from the user's browser. The
client instance ensures that this is the same user that was sent out by
validating session information and retrieves the stored pending
request. The client instance uses the values in this to validate the hash
parameter. The client instance then calls the continuation URL and presents the
handle and interaction reference in the request body. The client instance signs
the request as above.

~~~
POST /continue HTTP/1.1
Host: server.example.com
Content-Type: application/json
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...

{
    "interact_ref": "4IFWWIKYBC2PQ6U56NL1"
}
~~~



The AS retrieves the pending request based on the handle and issues
a bearer access token and returns this to the client instance.

~~~
Content-Type: application/json

{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
        "access": [{
            "actions": [
                "read",
                "write",
                "dolphin"
            ],
            "locations": [
                "https://server.example.net/",
                "https://resource.local/other"
            ],
            "datatypes": [
                "metadata",
                "images"
            ]
        }]
    },
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue"
    }
}
~~~




## Secondary Device Interaction {#example-device}

In this scenario, the user does not have access to a web browser on
the device and must use a secondary device to interact with the AS.
The client instance can display a user code or a printable QR code.
The client instance is not able to accept callbacks from the AS and needs to poll
for updates while waiting for the user to authorize the request.

The client instance initiates the request to the AS.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            "dolphin-metadata", "some other thing"
        ],
    },
    "client": "7C7C4AZ9KHRS6X63AJAO",
    "interact": {
        "start": ["redirect", "user_code"]
    }
}
~~~



The AS processes this and determines that the RO needs to interact.
The AS supports both redirect URIs and user codes for interaction, so
it includes both. Since there is no "callback" the AS does not include
a nonce, but does include a "wait" parameter on the continuation
section because it expects the client instance to poll for results.

~~~
Content-Type: application/json

{
    "interact": {
        "redirect": "https://srv.ex/MXKHQ",
        "user_code": {
            "code": "A1BC-3DFF",
            "url": "https://srv.ex/device"
        }
    },
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue/VGJKPTKC50",
        "wait": 60
    }
}
~~~



The client instance saves the response and displays the user code visually
on its screen along with the static device URL. The client instance also
displays the short interaction URL as a QR code to be scanned.

If the user scans the code, they are taken to the interaction
endpoint and the AS looks up the current pending request based on the
incoming URL. If the user instead goes to the static page and enters
the code manually, the AS looks up the current pending request based
on the value of the user code. In both cases, the user logs in, is
identified as the RO for the resource being requested, and approves
the request. Once the request has been approved, the AS displays to
the user a message to return to their device.

Meanwhile, the client instance periodically polls the AS every 60 seconds at
the continuation URL. The client instance signs the request using the
same key and method that it did in the first request.

~~~
POST /continue/VGJKPTKC50 HTTP/1.1
Host: server.example.com
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...
~~~



The AS retrieves the pending request based on the handle and
determines that it has not yet been authorized. The AS indicates to
the client instance that no access token has yet been issued but it can
continue to call after another 60 second timeout.

~~~
Content-Type: application/json

{
    "continue": {
        "access_token": {
            "value": "G7YQT4KQQ5TZY9SLSS5E",
            "bound": true
        },
        "uri": "https://server.example.com/continue/ATWHO4Q1WV",
        "wait": 60
    }
}
~~~


Note that the continuation URL and access token have been rotated since they were
used by the client instance to make this call. The client instance polls the
continuation URL after a 60 second timeout using this new information.

~~~
POST /continue/ATWHO4Q1WV HTTP/1.1
Host: server.example.com
Authorization: GNAP G7YQT4KQQ5TZY9SLSS5E
Detached-JWS: ejy0...
~~~



The AS retrieves the pending request based on the URL and access token,
determines that it has been approved, and issues an access
token for the client to use at the RS.

~~~
Content-Type: application/json

{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
        "access": [
            "dolphin-metadata", "some other thing"
        ]
    }
}
~~~


## No User Involvement {#example-no-user}

In this scenario, the client instance is requesting access on its own
behalf, with no user to interact with.

The client instance creates a request to the AS, identifying itself with its
public key and using MTLS to make the request.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json

{
    "access_token": {
        "access": [
            "backend service", "nightly-routine-3"
        ],
    },
    "client": {
      "key": {
        "proof": "mtls",
        "cert#S256": "bwcK0esc3ACC3DB2Y5_lESsXE8o9ltc05O89jdN-dg2"
      }
    }
}
~~~



The AS processes this and determines that the client instance can ask for
the requested resources and issues an access token.

~~~
Content-Type: application/json

{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token",
        "access": [
            "backend service", "nightly-routine-3"
        ]
    }
}
~~~


## Asynchronous Authorization {#example-async}

In this scenario, the client instance is requesting on behalf of a specific
RO, but has no way to interact with the user. The AS can
asynchronously reach out to the RO for approval in this scenario.

The client instance starts the request at the AS by requesting a set of
resources. The client instance also identifies a particular user.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            {
                "type": "photo-api",
                "actions": [
                    "read",
                    "write",
                    "dolphin"
                ],
                "locations": [
                    "https://server.example.net/",
                    "https://resource.local/other"
                ],
                "datatypes": [
                    "metadata",
                    "images"
                ]
            },
            "read", "dolphin-metadata",
            {
                "type": "financial-transaction",
                "actions": [
                    "withdraw"
                ],
                "identifier": "account-14-32-32-3", 
                "currency": "USD"
            },
            "some other thing"
        ],
    },
    "client": "7C7C4AZ9KHRS6X63AJAO",
    "user": {
        "sub_ids": [ {
            "subject_type": "email",
            "email": "user@example.com"
        } ]
   }
}
~~~



The AS processes this and determines that the RO needs to interact.
The AS determines that it can reach the identified user asynchronously
and that the identified user does have the ability to approve this
request. The AS indicates to the client instance that it can poll for
continuation.

~~~
Content-Type: application/json

{
    "continue": {
        "access_token": {
            "value": "80UPRY5NM33OMUKMKSKU",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 60
    }
}
~~~



The AS reaches out to the RO and prompts them for consent. In this
example, the AS has an application that it can push notifications in
to for the specified account. 

Meanwhile, the client instance periodically polls the AS every 60 seconds at
the continuation URL.

~~~
POST /continue HTTP/1.1
Host: server.example.com
Authorization: GNAP 80UPRY5NM33OMUKMKSKU
Detached-JWS: ejy0...
~~~



The AS retrieves the pending request based on the handle and
determines that it has not yet been authorized. The AS indicates to
the client instance that no access token has yet been issued but it can
continue to call after another 60 second timeout.

~~~
Content-Type: application/json

{
    "continue": {
        "access_token": {
            "value": "BI9QNW6V9W3XFJK4R02D",
            "bound": true
        },
        "uri": "https://server.example.com/continue",
        "wait": 60
    }
}
~~~



Note that the continuation handle has been rotated since it was
used by the client instance to make this call. The client instance polls the
continuation URL after a 60 second timeout using the new handle.

~~~
POST /continue HTTP/1.1
Host: server.example.com
Authorization: GNAP BI9QNW6V9W3XFJK4R02D
Detached-JWS: ejy0...
~~~



The AS retrieves the pending request based on the handle and
determines that it has been approved and it issues an access
token.

~~~
Content-Type: application/json

{
    "access_token": {
        "value": "OS9M2PMHKUR64TB8N6BW7OZB8CDFONP219RP1LT0",
        "bound": true,
        "manage": "https://server.example.com/token/PRY5NM33OM4TB8N6BW7OZB8CDFONP219RP1L",
        "access": [
            "dolphin-metadata", "some other thing"
        ]
    }
}
~~~




## Applying OAuth 2 Scopes and Client IDs {#example-oauth2}

While GNAP is not designed to be directly compatible with
OAuth 2 {{RFC6749}}, considerations have been made to enable the use of
OAuth 2 concepts and constructs more smoothly within GNAP.

In this scenario, the client developer has a `client_id` and set of
`scope` values from their OAuth 2 system and wants to apply them to the
new protocol. Traditionally, the OAuth 2 client developer would put
their `client_id` and `scope` values as parameters into a redirect request
to the authorization endpoint.

~~~
HTTP 302 Found
Location: https://server.example.com/authorize
  ?client_id=7C7C4AZ9KHRS6X63AJAO
  &scope=read%20write%20dolphin
  &redirect_uri=https://client.example.net/return
  &response_type=code
  &state=123455

~~~



Now the developer wants to make an analogous request to the AS
using GNAP. To do so, the client instance makes an HTTP POST and
places the OAuth 2 values in the appropriate places.

~~~
POST /tx HTTP/1.1
Host: server.example.com
Content-Type: application/json
Detached-JWS: ejy0...

{
    "access_token": {
        "access": [
            "read", "write", "dolphin"
        ],
        "flags": [ "bearer" ]
    },
    "client": "7C7C4AZ9KHRS6X63AJAO",
    "interact": {
        "start": ["redirect"],
        "finish": {
            "method": "redirect",
            "uri": "https://client.example.net/return?state=123455",
            "nonce": "LKLTI25DK82FX4T4QFZC"
        }
    }
}
~~~



The client_id can be used to identify the client instance's keys that it
uses for authentication, the scopes represent resources that the
client instance is requesting, and the `redirect_uri` and `state` value are
pre-combined into a `callback` URI that can be unique per request. The
client instance additionally creates a nonce to protect the callback, separate
from the state parameter that it has added to its return URL.

From here, the protocol continues as above.

# JSON Structures and Polymorphism {#polymorphism}

GNAP makes use of polymorphism within the [JSON](#RFC8259) structures used for
the protocol. Each portion of this protocol is defined in terms of the JSON data type
that its values can take, whether it's a string, object, array, boolean, or number. For some
fields, different data types offer different descriptive capabilities and are used in different
situations for the same field. Each data type provides a different syntax to express
the same underlying semantic protocol element, which allows for optimization and 
simplification in many common cases. 

Even though JSON is often used to describe strongly typed structures, JSON on its own is naturally polymorphic. 
In JSON, the named members of an object have no type associated with them, and any
data type can be used as the value for any member. In practice, each member
has a semantic type that needs to make sense to the parties creating and
consuming the object. Within this protocol, each object member is defined in terms
of its semantic content, and this semantic content might have expressions in
different concrete data types for different specific purposes. Since each object
member has exactly one value in JSON, each data type for an object member field
is naturally mutually exclusive with other data types within a single JSON object.

For example, a resource request for a single access token is composed of an array
of resource request descriptions while a request for multiple access tokens is
composed of an object whose member values are all arrays. Both of these represent requests
for access, but the difference in syntax allows the client instance and AS to differentiate
between the two request types in the same request.

Another form of polymorphism in JSON comes from the fact that the values within JSON
arrays need not all be of the same JSON data type. However, within this protocol, 
each element within the array needs to be of the same kind of semantic element for
the collection to make sense, even when the data types are different from each other.

For example, each aspect of a resource request can be described using an object with multiple
dimensional components, or the aspect can be requested using a string. In both cases, the resource
request is being described in a way that the AS needs to interpret, but with different
levels of specificity and complexity for the client instance to deal with. An API designer
can provide a set of common access scopes as simple strings but still allow
client software developers to specify custom access when needed for more complex APIs.

Extensions to this specification can use different data types for defined fields, but
each extension needs to not only declare what the data type means, but also provide
justification for the data type representing the same basic kind of thing it extends.
For example, an extension declaring an "array" representation for a field would need
to explain how the array represents something akin to the non-array element that it
is replacing. 
