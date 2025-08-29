---
RIP: 3
Title: Storage Layout
Author: '@fintohaps <fintan.halpenny@gmail.com>'
Status: Draft
Created: 2022-10-27
License: CC0-1.0
---

RIP #3: Storage Layout
======================
The storage layer is a crucial component of the Radicle network, and it is
designed with a local-first approach. This means that it can accommodate not
only the local operator's view of a repository, but also the views of peers in
whom the operator is interested. These views, also known as *forks* or *source
trees*, play a key role in enabling collaboration and version control within
the network.

Table of Contents
-----------------
* [Overview](#overview)
* [Layout](#layout)
* [Replication](#replication)
* [Working Copy](#working-copy)
    * [URL](#url)
    * [Refspecs](#refspecs)
    * [Example](#example)
    * [Remote Helper](#remote-helper)
        * [Authorization](#authorization)
* [Future Work](#future-work)
* [Appendix](#appendix)
    * [Alternative Designs](#alternative-designs)
        * [Associating a Working Copy](#associating-a-working-copy)
    * [Worked Example](#worked-example)
* [Credits](#credits)
* [Copyright](#copyright)

Overview
--------
In a peer-to-peer network, there is no centralized server or repository for
users to submit their changes. Additionally, the absence of a consensus
mechanism at the protocol level means that the sequence of operations cannot be
guaranteed. To tackle these issues, Radicle implements a partitioned approach
in which each user maintains their own local "fork" of a repository, as well as
any other forks they have an interest in. These forks are then shared among
users across the network. This method not only enhances the user experience by
allowing offline work but also eliminates the need for a server to process
data. Each repository fork has a single owner and writer, and users are only
permitted to make changes to their respective forks.

The storage layer must also be designed for efficient replication of data
between peers. For this reason, Git is used as the underlying protocol and
database, as it maps nicely to the type of data exchanged on the Radicle
network, and is flexible enough for our use case. In addition, Git has been
optimized for speed and disk space, and will automatically de-duplicate
repository data and fetch missing objects from peers[^0].

With the above in mind, this document proposes a storage layer that meets the
following requirements:

1. The storage layer is capable of maintaining a local copy of the working
   dataset.
2. The storage layer can store any number of repositories.
3. For each repository, it can represent multiple views, or *forks*, of
   the repository.
4. The storage layer can natively interoperate with Git.

There are two aspects to consider for Git interoperability:

1. Repository replication between peers.
2. Associating a *working* repository or "copy" with a *stored* repository.

In the next sections we will cover how the above works with the storage layout.

Layout
------
The storage layout must support multiple repositories and multiple peers per
repository. Each stored repository is a *bare* Git repository[^1]. To ensure
uniqueness and easy identification of repositories, a stable and globally
unique identifier, known as the Repository ID (RID), is assigned to each
stored repository. The RID for each repository is established according to the
guidelines provided in RIP#2's section *The Repository Identifier*, and is
represented as `<rid>` in diagrams found in this document.

Since our underlying storage uses Git, we represent the storage layout as a
file tree on the file-system, with `<storage>` representing the storage root,
or top-level directory under which all repositories are stored on a user's
device. Though this storage tree is browsable by the user with standard file
system commands, it is not meant to be interacted with directly by users,
for risk of corrupting the data. Additionally, Git is free to pack the objects,
which means they may not always appear as individual files.

    <storage>       # Storage root containing all local repositories
    ├── <rid>       # Some repository, e.g. a project, as a bare git repository
    │   └── refs    # All Git references under this project
    ├── <rid>
    │   └── refs
    ├── <rid>
    │   └── refs
    └── ...

<small>Basic overview of the storage layout with multiple repositories</small>

For every repository, each peer associated with that repository must have a
separate, logical Git source tree -- which contains all the usual reference
namespaces, i.e. `heads`, `tags`, and `notes`. This *logical repository* is
what we call *fork* or *view*, and allows peers to maintain different sets of
changes for the same physical repository.

    <storage>
    └─ <rid>                    # The "physical" Git repository
       └─ refs
          └─ namespaces         # All forks are stored under this namespace
             ├─ <nid>           # One peer's fork is stored here
             │  └─ refs
             ├─ <nid>           # Another peer's fork is stored here
             │  └─ refs
             └─ <nid>           # Etc.
                └─ refs

<small>Storage partitioning by Node ID or `<nid>`</small>

To have this separation, instead of having each peer stored in a separate Git
repository with a separate object database (ODB), the `gitnamespaces`[^2]
feature is used. For each peer, including the local peer, their unique
identifier is used as the namespace within each repository to separate Git
objects. The identifier used is described in *Peer Identity* in RIP#2, and is
usually known as the *Node Identifier* (NID):

> In Heartwood, peers are simply identified by their public key. This
> key is an Ed25519 key that is encoded as a DID using the `did:key`
> method. DIDs are used for interoperability with other systems as
> well as allowing for other types of identifiers in the future.

Thus, each peer can have its own namespace for references, while sharing the
objects with other peers via a shared ODB. This ensures only one copy of each
object is stored across all repository forks.

The storage uses the encoded public key portion of the `did:key` string as the
namespace path, denoted as `<nid>` or *Node ID* going forward. This means that
a peer's references will be scoped by their Node ID via the path prefix
`refs/namespaces/<nid>`. We demonstrate this organisation below in more detail:

    <storage>                     # Storage root containing all local repositories
    ├─ <rid>                      # Storage for first repository
    │  └─ refs                    # All Git references locally stored
    │     └─ namespaces           # All peer source trees or "forks"
    │        ├─ <nid>             # First node's source tree
    │        │  └─ refs           # First node's Git references
    │        │     ├─ heads       # First node's branches
    │        │     │   └─ master  # First node's master branch
    │        │     ├─ tags        # First node's tags
    │        │     │   ...
    │        │     └─ rad
    │        │         └─ id      # First node's version of the repository identity document
    │        │
    │        └─ <nid>             # Second node's source tree
    │           ├─ refs           # Second node's references
    │           └─ ...
    ├─ <rid>                      # Storage for second repository
    │   ...
    └─ <rid>                      # etc.
        ...

Note that top-level references may still exist, i.e. `<rid>/refs/{heads,tags}`.
The top-level namespace must be reserved for canonical references --
references that are agreed upon collaboratively, as published and stable. They
do not belong to any one peer and thus may be different on each device. How
canonical references are decided and written is left for a future RIP.

    <storage>
    └─ <rid>
       └─ refs
          ├─ HEAD                 # Canonical head reference
          ├─ heads                # Canonical branches
          │   └─ master           # Canonical master branch
          ├─ tags
          │   └─ v1.0.0           # Canonical v1.0.0 release tag
          ├─ rad
          │   └─ id               # Canonical identity reference
          └─ namespaces           # All peer source trees
             ├─ <nid>             # First node's source tree
             └─ <nid>             # Second node's source tree
             ...

<small>Example of canonical references under a repository</small>

Replication
-----------
Repository replication involves retrieving data from a remote peer. As the
storage consists of Git repositories, data can be transferred remotely using
the Git protocols[^3] and appropriate refspecs[^4]. However, this document does
not cover the protocol used or how to verify fetched data, as those topics are
beyond its scope. They may be discussed in a separate document.

That being said, we designed the storage layout such that it's easy to transfer
data between repositories over the network, using an unmodified Git protocol.
Using refspecs, it's possible to transfer only the objects we're interested in,
for example we can fetch only a certain peer's fork and not another.

Working Copy
------------
A working copy is a local copy of a repository, which corresponds to a
repository in storage. The operator can make changes to the source code in the
working copy. This is similar to how one would use `git clone` to obtain a copy
of an upstream repository, such as one hosted on GitHub or GitLab. Once the
changes have been made in the working copy, they can be pushed upstream. With
Radicle, changes are fetched and pushed between the *working* copy and the
*stored* copy within the local storage.

The connection between the working copy and the storage is maintained through a
set of Git remotes[^5], where each remote represents a single remote peer or
*namespace* for that repository and is associated with a Node ID.

The name of each remote, defined by the operator or application, can be
customized to suit their preferences. For instance, the operator may use the
Node ID of the peer, `origin`, `rad`, a nickname, or any other desired name.
By convention, we use the `rad` remote for the local peer's remote, such that
a user may push changes to his or her own fork with `git push rad`.

The URL of each Git remote must resolve the local storage's repository
corresponding to the working copy. As such, the URL serves as a mapping between
the working copy and the stored copy.

### URL

The URL scheme for a given Radicle remote is of the form:

    rad://<rid>[/<nid>]

* The `rad://` scheme is used for Radicle repositories, and identifies a
  project on the network. By using this scheme with Git, the user instructs Git
  to invoke the `git-remote-rad` executable during `git push` or `git fetch`,
  which allows the user to interact with the network through the storage layer.
  This will be covered in more detail in the *Remote Helper* section.
* The `<rid>` component is the repository identifier to be found in storage.
* The `<nid>` component is the Node ID which the `--namespace` option will
  be set to. If `<nid>` is not specified, Git will interact with the
  repository's *canonical references*.

Here's an example URL for repository `z42hL2jL4XNk6K8oHQaSWfMgCL7ji` and peer
`z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi`:

	rad://z42hL2jL4XNk6K8oHQaSWfMgCL7ji/z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi

Here's a URL for the same repository's canonical references:

	rad://z42hL2jL4XNk6K8oHQaSWfMgCL7ji

### Refspecs

Since Git namespaces are used, the `fetch` refspec[^4] may be:

    +refs/heads/*:refs/remotes/<name>/*

The operator may also want to scope tags to particular remotes. This
can be achieved by using the `tagOpt` of a remote and adding another
fetch refspec.

    fetch = +refs/tags/*:refs/remotes/<name>/tags/*
    tagOpt = --no-tags

When using these refspecs with `git fetch` or `git push`, it is necessary to
specify the namespace that is being used for the operation. This can be
achieved using `git --namespace=<nid>` or `GIT_NAMESPACE=<nid> git`.
Unfortunately, this is somewhat cumbersome for the user and does not prevent
pushing to namespaces belonging to a non-local peer. This is remedied in
[Remote Helper](#Remote-Helper).

### Example

Here's an example remote configuration based on the above specifications:

    [remote "rad"]
        url = rad://z42hL2jL4XNk6K8oHQaSWfMgCL7ji/z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi
        fetch = +refs/heads/*:refs/remotes/rad/*

To support fetching canonical references while pushing to the local peer's
namespace, a configuration like the following can be used:

    [remote "rad"]
        url = rad://z42hL2jL4XNk6K8oHQaSWfMgCL7ji
        pushurl = rad://z42hL2jL4XNk6K8oHQaSWfMgCL7ji/z6MknSLrJoTcukLrE435hVNQT4JUhbvWLX4kUzqkEStBU8Vi
        fetch = +refs/heads/*:refs/remotes/rad/*

In the above configuration, `git pull rad` would pull the canonical references
while `git push rad` would push to the local user's namespace.

For a more thorough example, see the [Appendix](#Appendix).

### Remote Helper

The remote helper is what allows Git to interpret URLs with the `rad://`
scheme.

As mentioned in the [Working Copy](#Working-Copy) section, there is currently
no way to configure a Git remote to be aware of additional logic, such as the
appropriate `refs/namespaces` to use (to avoid having to use `--namespace`) or
to prevent pushing to other peers' namespaces.

To address these requirements, a `git-remote-rad` helper binary can be
introduced to supply the necessary namespace and enforce the correct use of
peer namespaces.

`git-remote-rad` is a gitremote-helper[^8] binary. When Git encounters a URL
that uses the `rad` transport protocol, it delegates the call to
`git-remote-rad`, which should be found in the operator's path, during a
`fetch` or `push` operation.

#### Authorization

With the remote helper installed, `git push` can automatically set
`GIT_NAMESPACE` to the Node ID of the current user after verifying that it
matches the one specified in the URL, and reject pushes to other Node IDs.

When fetching, the remote helper can set `GIT_NAMESPACE` to whatever Node ID
is specified in the URL, as no authorization is required to fetch.

Future Work
-----------
You may have noticed that in this [layout](#Layout) the top-level namespace
is left for canonical references. The definition and verification of canonicity
is left for a future RIP.

Appendix
--------

### Alternative Designs

An alternative design for organizing peer source trees is to use the `remotes`
namespaces, i.e. `refs/remotes/<nid>`. This particular namespace is deemed
special by `git` and its tooling. A "remote" reference is one that corresponds
to a remote location. The remote location and how to fetch/push from/to is
configured using `git remote`[^6]. When `git fetch` is used for that remote, it
will place the references under `refs/remotes`[^7].

#### Associating a Working Copy

Continuing along this line of enquiry, we look at how this storage will link to
a working copy -- our personal directory for editing the code. As we previously
said, we will want to setup a remote in the working copy. This will look like
the following:

    [remote "alice"]
    url = file:///path/to/storage
    fetch = +refs/remotes/alice/heads/*:refs/remotes/alice/*

This will do what you expect when running:

    $ git fetch alice

However, you may be surprised that when running:

    $ git fetch alice master
    fatal: couldn't find remote ref master

It will not result in fetching the latest changes from `master`. In fact, it
will say no reference exists. To get the exact `master` we are looking for we
must run:

    $ git fetch alice refs/remotes/alice/heads/master

To explain, `git` tends to work under a DWIM (Do What I Mean) principle. The
`master` in `git fetch alice master` is ambiguous, in general. It could be
`refs/heads/master`, `refs/remotes/origin/master`,
`refs/remotes/alice/heads/master`, etc. `git` will assume that what you meant
was `refs/heads/master` and will look for this on the remote end, but of course
it does not exist.

This problem is only compounded with `refs/tags`[^7], where pushing a tag to a
remote will always DWIM and target the `refs/tags` namespace -- unless
otherwise specified.

Thus, we see that this design is not adequate.

### Worked Example

To begin we want to set up three git repositories: `storage`, `project`, and
`fork`. The `storage` repository will act like the Radicle storage, while
`project` and `fork` are working copies that will be linked to `storage` via
their remote entries.

    # Storage setup
    $ mkdir storage
    $ cd storage
    $ git init --bare

    # Project setup
    $ mkdir project
    $ cd project
    $ git init

    # Fork setup
    $ mkdir fork
    $ cd fork
    $ git init

#### Pushing Changes

Our first action will be to make changes in `project` and push them to
`storage`. In order for us to do that we need to create a remote in `project`,
create a commit, and push it to `storage`.

    # Add remote: "alice" will be used instead of a Node ID
    $ cd project
    $ git remote add alice file:///home/user/radicle/storage

    # Add a commit
    $ touch README.md && git add README.md && git commit -am "Add README"
    $ git --namespace=alice push alice master

`git` will then print out that it pushed a new branch and we can confirm by
inspecting the `refs` in `storage`.

    # Inspect refs
    $ cd storage
    $ tree refs
    refs
    ├── heads
    ├── namespaces
    │   └── alice
    │       └── refs
    │           └── heads
    │               └── master
    └── tags

#### Fetching Changes

Our next action will be to fetch the changes from `alice` in the `fork`
repository. To do this, we must add a remote -- like before -- and run a `git
fetch`.

    # Add remote; alice will mimic the public key hash
    $ cd fork
    $ git remote add alice file:///home/user/radicle/storage

    # Fetch the changes
    $ git --namespace=alice fetch alice

This will fetch the `heads` from `alice` and put them under the remote `alice`.
We can confirm this by inspecting the `refs` in `fork`.

    # Inspect refs
    $ tree .git/refs
    .git/refs
    ├── heads
    ├── remotes
    │   └── alice
    │       └── master
    └── tags

#### Different Peers

To imitate the reality that there will be a namespace per peer, we add a new
remote for `fork`. We can then make changes to `alice/master` and publish it
under the `bob` namespace.

    # Add bob remote
    $ git remote add bob file:///home/user/radicle/storage

    $ git merge bob/master
    $ echo "Hello, Radicle" >> README.md
    $ git commit -am "Hello, Radicle"
    $ git --namespace=bob push bob master

Again, we can confirm this did what we wanted in `storage`.

    # Inspect storage refs
    cd storage
    tree refs
    refs
    ├── heads
    ├── namespaces
    │   ├── alice
    │   │   └── refs
    │   │       └── heads
    │   │           └── master
    │   └── bob
    │       └── refs
    │           └── heads
    │               └── master
    └── tags

#### Non-global Tags

Often we find that pushing tags pollutes the `refs/tags` namespace since they
do not get placed under `remotes` when fetching. With the use of the
`gitnamespaces` feature we avoid this.

    $ cd fork
    $ git tag v1.0.0
    $ git push v1.0.0

    # Inspect storage refs
    refs
    ├── heads
    ├── namespaces
    │   ├── alice
    │   │   └── refs
    │   │       └── heads
    │   │           └── master
    │   └── bob
    │       └── refs
    │           ├── heads
    │           │   └── master
    │           └── tags
    │               └── v1.0.0
    └── tags


This shows that namespaces are superior in organising references correctly for
each given peer.

Credits
-------
* Kim Altintop, for shining the light on the lesser known `gitnamespaces`[^2]
  feature while developing `radicle-link`.
* Alex Good, for attempting to implement a feature dubbed "ref rewriting" to
  solve the remotes problem, before realising that using `gitnamespaces`[^2]
  could be a better option.

Copyright
---------
This document is licensed under the Creative Commons CC0 1.0 Universal license.

[^0]: https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols
[^1]: https://git-scm.com/docs/git-init#Documentation/git-init.txt---bare
[^2]: https://git-scm.com/docs/gitnamespaces
[^3]: https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols
[^4]: https://git-scm.com/book/en/v2/Git-Internals-The-Refspec
[^5]: https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes
[^6]: https://git-scm.com/docs/git-remote
[^7]: https://git-scm.com/book/en/v2/Git-Internals-Git-References
[^8]: https://git-scm.com/docs/gitremote-helpers
