---
RIP: 2
Title: Identity
Author: '@cloudhead <cloudhead@radicle.xyz>'
Status: Draft
Created: 2022-12-06
License: CC0-1.0
---

In RIP #1, we discussed *repository identity*, and the *identity document*.
We said that to make it possible for repositories to be hosted in a peer-to-peer
network, Git repositories on their own are not enough: we need a secure way to
identify repositories that goes beyond source code. We need a stable identifier
and a mechanism for self-certifying repositories against this identifier,
so that changes to source code can be verified locally, by users.

In this RIP, we discuss the method through which we can achieve the above in
a secure, decentralized way.

Table of Contents
-----------------
* [Overview](#overview)
* [Peer Identity](#peer-identity)
* [Repository Identity](#repository-identity)
    * [Validation](#validation)
* [The Repository Identifier](#the-repository-identifier)
* [Identity Storage](#identity-storage)
    * [Verification](#verification)
* [Security](#security)
* [Closing Thoughts](#closing-thoughts)
* [Credits](#credits)
* [Copyright](#copyright)

Overview
--------
To introduce the topic of identity, we point the reader to the opening
paragraphs of the original specification of identities on the Radicle network,
which is still very much applicable to the Heartwood protocol:

> In order to collaborate on repositories within a consensus-free network, we
> must be able to refer to them using a stable identifier. Note that this
> identifier is a statement of intent: a repository can be described as a
> collection of ever-moving leaves of a DAG whose root element is the empty
> object. Therefore, the content of a repository is not enough to describe it –
> while two views on the repository may share objects, they may diverge
> substantially otherwise. Both views may however state their intent to
> eventually converge to the same state.
>
> While in principle a random identifier with sufficient entropy would suffice
> for the purpose, this would put the burden of deciding which repository views
> are legitimate entirely on the user. Instead, our approach is to establish an
> ownership proof, tied to the network identity of a peer, or set of peers,
> such that repository views can be replicated according to the trust
> relationships between peers (“tracking”).
>
> Our model is loosely based on The Update Framework (TUF)[^0], conceived as a
> means of securely distributing software packages.

With this in mind, there are three core components to the Radicle identity
system, for any given repository:

1. A set of peers on the network, each holding a signing key.
2. A document which establishes the identity of this repository, using these
   signing keys to self-certify.
3. A stable identifier that can be used to refer to the repository, derived
   from this document.

Peer Identity
-------------
Since Radicle repositories on the network are created by peers, we must first
establish the concept of a *peer identity*. In Heartwood, peers are simply
identified by their public key. This key is an Ed25519[^1] key that is encoded
as a DID using the `did:key` method[^2]. DIDs are used for interoperability
with other systems as well as allowing for other types of identifiers in the
future.

    did:key:z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi

*Example of a peer identifier in DID format.*

We'll also note that peers on the network -- also called *nodes* are
indistinguishable from *users* at the protocol level. The terms "Node ID",
"Peer ID", "Public Key" are thus all used interchangeably.

Repository Identity
-------------------
With the establishment of peer identities, we can now move on to repository
identities. A repository identity consists of an identity document and an
associated unique identifier.

The identity document is a JSON document associated with a repository on Radicle.
The *hypothetical* minimal identity document looks like this:

    { "delegates": ["did:key:z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi"],
      "threshold": 1 }

It describes a repository with a single *delegate*. Delegates are trusted
entities that can cryptographically sign data within the scope of a given
repository. In the identity document, they are represented by a DID. As of this
RIP, only the `did:key` method is supported.

Using the `threshold` property, the document specifies that only *one* delegate
is required to sign updates to the repository. In this case, since we only
have one delegate, this is the only possible value for `threshold`.

> Repository delegates are responsible for signing all updates to a repository,
> whether it be source code commits or updates to the identity document itself.
> They can be thought of as repository "maintainers", though the applicability
> is broader. We will see how delegates sign repository updates in one of
> the following sections.

Though the above document could constitute a valid identity, it does not contain
any identifiable data that may be used to describe a particular repository.
This is what the `payload` section is for. Heartwood defines a single payload
type, `xyz.radicle.project`, which can be used to describe a project stored
in a repository:

    { "delegates": ["did:key:z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi"],
      "threshold": 1,
      "payload": {
        "xyz.radicle.project": {
          "name": "heartwood",
          "description": "Radicle Heartwood Protocol & Stack",
          "defaultBranch": "master"
        }
      }
    }

The string `xyz.radicle.project` is called a *payload ID*, and the `project`
payload is the default payload type for Radicle repositories. Using this payload,
type, a repository may be given a name, a description, and a default branch.

Identity documents are designed to be extensible, and developers may create
their own payload types and applications can choose which payload types to
support.

    { ...
      "payload": {
        "xyz.radicle.project": { ... },
        "xyz.radicle.funding": { ... },
        "com.atproto.account": {
          "email": "eve@atproto.com",
          "handle": "eve"
        }
      }
    }

<small>Figure 1. Fictional example of an identity with multiple payloads</small>

Payload IDs use reverse domain-name notation[^3] and are comprised of two
parts: an *authority*, eg. `radicle.xyz`, and a *name*, eg. `project`. To keep
payload types globally unique, developers wishing to create new payload types
must control the authority (domain) under which these live.

As of this RIP, there is only one recognized payload type: `xyz.radicle.project`.
Repositories which include this type of payload are sometimes called *projects*.

> When specifying new payload types, it's worth thinking about how the payload
> schema might evolve over time. For example, it might be worth versioning the
> payload types, either via the identifier (eg. `com.atproto.account.v1`) or
> via a field inside the payload (eg. `{"version": 1}`). This will ensure that
> changes to the payload schema are able to be made in a backwards compatible
> way.

### Validation

An identity document is valid if the following conditions are met:

* There is at least *one* `delegate`, but no more than `255`.
* Strings are not empty, and at most `255` characters long.
* The `threshold` is not zero and not greater than the number of `delegates`.
* The items in `delegates` are valid DIDs.
* There is a `payload` property with at least one payload object and a valid
  payload ID.
* Each payload under `payload` is valid according to the rules of that payload.

These rules can be partly described in the following JSON Schema[^4] document:

    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": {
        "delegates": {
          "type": "array",
          "items": [{ "type": "string" }],
          "minItems": 1,
          "maxItems": 255,
          "uniqueItems": true
        },
        "threshold": {
          "type": "integer",
          "minimum": 1,
          "maximum": 255
        },
        "payload": {
          "type": "object",
          "additionalProperties": { "type": "object" },
          "minProperties": 1
        }
      },
      "required": ["delegates", "threshold", "payload"]
    }

Finally, the schema and validation rules for the `xyz.radicle.project` payload
are described as:

    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1,
          "maxLength": 255
        },
        "description": {
          "type": "string",
          "maxLength": 255
        },
        "defaultBranch": {
          "type": "string",
          "minLength": 1,
          "maxLength": 255
        }
      },
      "required": ["name", "description", "defaultBranch"]
    }

The Repository Identifier
-------------------------
Now that we have a document describing our repository, we can derive from it
a unique identifier that can be used to refer to the repository on the
peer-to-peer network. This identifier must meet certain criteria:

1. It must be *stable*, in other words it must not change throughout the
   lifetime of the repository.
2. It must be deterministically derivable from the identity document alone, for
   the purpose of verification.
3. It must contain enough entropy to be globally unique.
4. It must allow for easy retrieval of the document from storage.

To fulfill the above, and given that Radicle uses Git for storage of repository
data, we choose to use the *Git Object ID*[^5] of the identity document, as
identifier. Git object IDs, or *OIDs* are "hardened" SHA-1 checksums of their
content, prefixed with a short header. We can compute this OID using the `git
hash-object` command. But before doing so, we must take care of one last thing:
to make the process of hashing our identity document fully deterministic, we
must first ensure our document is in canonical JSON form[^6]. This prevents
things like whitespace or key ordering from influencing the document hash and
therefore the identifier. In turn, this makes the identifier easier to compute
correctly.

The above document in canonical form looks like this:

    {"delegates":["did:key:z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi"],
    "payload":{"xyz.radicle.project":{"defaultBranch":"master","description":
    "Radicle Heartwood Protocol & Stack","name":"heartwood"}},"threshold":1}

We can now compute the Git object ID by placing the above JSON in a file, eg.
`radicle.json`, taking care to strip all newline characters from it, and
running the following command:

    $ git hash-object -t blob radicle.json

The output should be:

    d96f425412c9f8ad5d9a9a05c9831d0728e2338d

This SHA-1 hash is the document's OID. To turn it into a Radicle repository
identifer, we encode the underlying 20-byte hash value using `multibase`
encoding[^7] with the `base-58-btc` alphabet; the same encoding used for the
`did:key` method, and prefix `rad:` to it, making it a valid URN:

    "rad" ":" multibase(base58-btc, raw-oid-bytes)

This results in the repository identifier, or RID:

    rad:z42hL2jL4XNk6K8oHQaSWfMgCL7ji

This RID is theoretically unique thanks to the entropy provided by the delegate
key and payload.

Identity Storage
----------------
A storage system suitable for storing identity documents must have two
properties:

1. It must guarantee data integrity.
2. It must preserve the history of changes to the documents.

Radicle repositories are stored in Git, and criteria (1) is guaranteed by Git
natively, so long as we store our identity documents in the Git object database.
This is because Git hashes all objects under it, and structures its data such
that a change in hash of one object means a change in hash of all dependent
objects.

Criteria (2) can be guaranteed by encoding changes to the documents as a Git
commit history. Not only does a commit history allow us to preserve all changes,
it also proves, via hash-linking that no change was omitted from the history.

    Commit             Commit             Commit
    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │ fb8e40a     │◄─┐ │ c581f25     │◄─┐ │ 43eb12d     │
    │             │  └─┤ fb8e40a     │  └─┤ c581f25     │
    │ ┌──────────┐│    │ ┌──────────┐│    │ ┌──────────┐│
    │ │ Document ││    │ │ Document ││    │ │ Document ││
    │ ├──────────┤│    │ ├──────────┤│    │ ├──────────┤│
    └─┴──────────┴┘    └─┴──────────┴┘    └─┴──────────┴┘

In the above diagram, we see three commits, with the left-most being the *root*
commit of the document, ie. the initial state, and the right-most being the
*head*, ie. the latest state.

Each commit includes within its Git tree, a blob named `radicle.json` which
contains a version of the identity document.

    ┌───────┬─────────┐                                   ┌─────┬───────────┐
    │commit │ fb8e40a │   ┌─────┬────────────────────┐  ┌►│blob │ d96f425   │
    ├───────┴─────────┤ ┌►│tree │ 82bc09a            │  │ ├─────┴───────────┤
    │tree   82bc09a   ├─┘ ├─────┴────────────────────┤  │ │{"delegates":...,│
    │author ...       │   │blob d96f425 radicle.json ├──┘ │ "payload":...,  │
    │                 │   └──────────────────────────┘    │ "threshold":...}│
    └─────────────────┘                                   └─────────────────┘

Using this representation, we can hence track all changes to a given identity.
To keep track of the head of this history, we use a special Git reference
named `rad/id` which points to the latest version of the identity document:

    fb8e40a ◄─ c581f25 ◄─ 43eb12d ◄─ refs/rad/id

Just like regular Git branches, when the identity is updated, `refs/rad/id`
is reset to point to the latest commit. Note that this commit history is
completely separate from the source code history pointed to by eg.
`refs/heads/master` and other branches. The identity history is kept in
the repository's *stored copy*, which is a bare repository, and is not included
in working copies.

### Verification

Verifying the latest state, ie. commit `43eb12d` is a matter of verifying all
preceding states, starting from the root (`fb8e40a`).

The root commit is verifiable intrinsically, since it contains as part of its
Git tree, the document from which we derived the RID. We can see above that the
original blob from which we computed the repository identifier is contained in
the tree pointed to by the root commit of the document history. The root commit
is hence valid for a given RID if and only if it contains a blob under the name
`radicle.json` containing a valid identity document which hashes to the given
RID, *and* the commit is signed by all delegates in the initial `delegates` list.

Once the root commit is verified, we can proceed to the next commit. Since
the document may have changed in this commit, the RID is no longer useful for
verifying this commit. Instead, we make sure that two conditions are fulfilled:

1. The commit containing the updated document is signed by a number of keys
   greater than or equal to the `threshold` property of the *previous*, valid
   version of the document.
2. Each of the aforementioned signatures belongs to a key that is part of the
   `delegates` set of the previous document version.

> Git commit signatures can be verified with the `git verify-commit` tool.

These delegate signatures are expected to be included in the commit header
under the `gpgsig` key, and be encoded in the SSH signature format.

    tree c66cc435f83ed0fba90ed4500e9b4b96e9bd001b
    parent af06ad645133f580a87895353508053c5de60716
    author Buck Mulligan <buck@mulligan.xyz> 1664467633 +0200
    committer Buck Mulligan <buck@mulligan.xyz> 1664786099 -0200
    gpgsig -----BEGIN SSH SIGNATURE-----
     U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgvjrQogRxxLjzzWns8+mKJAGzEX
     4fm2ALoN7pyvD2ttQAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
     AAAAQIQvhIewOgGfnXLgR5Qe1ZEr2vjekYXTdOfNWICi6ZiosgfZnIqV0enCPC4arVqQg+
     GPp0HqxaB911OnSAr6bwU=
     -----END SSH SIGNATURE-----
    gpgsig -----BEGIN SSH SIGNATURE-----
     U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgDb3ulFKnHALG8AnuuFPY9prvVZ
     kyLc73tcQ+HG3sCzQAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
     AAAAQM9rxErTt7AtcLypSyVM/jmd9/syO4D5hjMjL/9lbGzIkXXDL6+QlUsLipeLuYHV92
     F/6nm/lEaPUTeiZQ5o9AI=
     -----END SSH SIGNATURE-----

<small>A Git commit header with two SSH signatures.</small>

We proceed in this manner until the last commit in the history. If all commits
pass this verification process, we consider the identity valid. Note that every
version of the document must be validated according to the rules stated under
the [Validation](#validation) section. This includes the document payload,
and implies that application developers supporting payload extensions will
have to provide their own validation for these payloads, that will have to run
for each commit in the document history.

It's important to restate that for any commit `C`, other than the root commit,
verification is done by using the `delegates` and `threshold` values of the
*parent* commit to `C`, which has already been verified.

Security
--------
The combination of Git storage and cryptographic verification provides very
strong security and integrity guarantees around Radicle repositories and
identities:

* Omitted data up to the latest commit is detected by Git itself
* Tampering with the identity root will result in a different RID
* Adding a delegate key without the sign-off of the existing delegate set will
  fail verification

There is one possible attack that can be carried out by network participants:
serving old data. Since it isn't possible to know whether a document history
has a more recent update than the latest known update, a dishonest peer may
choose to hide the last *N* identity updates from its peers. This means it
will serve a stale document to its peers.

However, this attack is only effective if *all* of a victim's connected peers
perform this censorship. It takes only one honest peer to serve the full
document history for the censorship to fail.

Closing Thoughts
----------------
In this RIP we described an identity system for Git repositories that can be
used to securely distribute code on a peer-to-peer network. The system is
self-certifying and requires only basic Git primitives to implement.

Credits
-------
* Kim Altintop, for the original design this system is based on

Copyright
---------
This document is licensed under the Creative Commons CC0 1.0 Universal license.

[^0]: https://theupdateframework.github.io/specification/latest/
[^1]: https://ed25519.cr.yp.to/
[^2]: https://w3c-ccg.github.io/did-method-key/
[^3]: https://en.wikipedia.org/wiki/Reverse_domain_name_notation
[^4]: https://json-schema.org/
[^5]: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects
[^6]: https://datatracker.ietf.org/doc/html/rfc8785
[^7]: https://w3c-ccg.github.io/multibase/
