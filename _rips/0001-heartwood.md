---
RIP: 1
Title: Heartwood
Author: '@cloudhead <cloudhead@radicle.xyz>'
Status: Draft
Created: 2022-09-06
License: CC0-1.0
---

In this RIP, we define a major iteration of the Radicle network protocol and
the various related sub-systems. We call it "Heartwood".

The intent of this proposal is not to define a complete specification of the
protocol, but to be a foundation for subsequent RIPs. Various aspects
of the protocol, in particular around the issues of privacy, censorship
resistance, peer misbehavior and DoS are left for future RIPs to expand on,
and won't be tackled here. Additionally, details and specifics on the wire
protocol, message formats, hash functions and encodings may be left out,
to focus this proposal on the big ideas.

Overview
--------
The Radicle network protocol can be defined through the intended use-case for a
peer-to-peer code hosting network:

*Alice publishes a repository on the network under a unique identifier, and
Bob, using that identifier is able to retrieve it from the network whether
Alice is online or offline, and verify the authenticity of the data.*

The above must hold true independent of the network topology and number of
nodes hosting the project, as long as at least one node is hosting it. We can
therefore say that the primary function of the protocol is to locate repositories
on the network, and serve them to users, all in a timely, and resource-efficient
manner.

This functionality can be broken down into three components:

1. Locating repositories, ie. finding which nodes host a given repository
2. Replicating a given repository between two nodes, such that they both
   hold a copy
3. Verifying the authenticity of all the data retrieved from the network, such
   that any node can serve any data without the need for trust

To achieve (1), nodes need to exchange information about which repositories
they host, so that they can point users to the right locations, as well as
notify each other when there are updates to the repositories. This in turn
requires *peer* discovery: nodes need a way to find each other on the network.

To achieve (2), git is used for its excellence as a replication protocol.

To achieve (3), given the nature of peer-to-peer networks, ie. that any node
can join the network, git alone is not enough. Replication through git needs to
be paired with a way of verifying the authenticity of the data being
replicated. While git checks for data *integrity*, our protocol will have to
make sure that the data Bob downloads is the data Alice published on the
network. Without such verification, an intermediary node on the network could
easily tamper with the data before serving it to Bob. We also can't require
that Alice serve her data directly to Bob, as that would require them to be
online at the same time, and would introduce a single point of failure.

Table of Contents
-----------------
* [Repository Identity](#repository-identity)
    * [The Identity Document](#the-identity-document)
* [Repository Discovery](#repository-discovery)
    * [Topology](#topology)
    * [Routing](#routing)
* [Node Identity](#node-identity)
* [Gossip](#gossip)
    * [Inventory Announcements](#inventory-announcements)
        * [Pruning](#pruning)
    * [Reference Announcements](#reference-announcements)
    * [Node Announcements](#node-announcements)
        * [Bootstrap Nodes](#bootstrap-nodes)
* [Replication](#replication)
    * [Project Tracking and Branches](#project-tracking-and-branches)
    * [Unintentional Forks and Conflicts](#unintentional-forks-and-conflicts)
* [Storage](#storage)
    * [Layout](#layout)
        * [Special References](#special-references)
* [Canonicity](#canonicity)
* [Closing Thoughts](#closing-thoughts)
* [Credits](#credits)
* [Copyright](#copyright)

Repository Identity
-------------------
To locate, or even "talk" about repositories on a peer-to-peer network, we
require a stable, unique identifier that can be verifiably associated with a
repository. Without this, there is no way for a user to request a specific
repository and verify its authenticity. Unlike centralized forges such
as GitHub, where repositories are deemed authentic based on their *location*,
eg. `https://github.com/bitcoin/bitcoin`; in an *untrusted* network, location
is not enough and we need a way to automatically verify the data we get from any
given location. Therefore, before we talk about networking, we must make a
little detour into repository identity.

It's important to understand that although git repositories use content
addressing for their objects, repositories are *mutable* data-structures.
Therefore, the identity of a repository *cannot* be derived solely from its
contents. Instead, the identity must be determined by some other authority.
In Radicle, this is no other than the *maintainers* of the repository, since it
is their mandate to decide what gets merged into a codebase.

We can then define a repository's identity as the set of all branches and tags
that the maintainers of the repository agreed upon at a given point in time,
along with a unique identifier.

For anyone to be able to verify an identity, we require maintainers to provide a
cryptographic signature over the repository's heads, tags, and other relevant
git references, along with repository metadata such as name and description.
We call this the *signed refs*. Signed refs can be updated whenever there are
changes to a repository that are accepted by maintainers. They represent a
repository's *canonical state*.

As for the identifier, it must be provably associated with the above state.
In other words, it must be possible, given an identifier and a set of signed
refs, to prove association.

### The Identity Document

Before a repository can be published to the network, it needs to be initialized
into a Radicle *project*. A project is simply a repository with an associated
*identity document*. In this document, the public keys of the repository's
current maintainers are stored. When a project is initialized from an existing
git repository for the first time, the user initializing becomes the de-facto
initial maintainer of the project, and his key is included in the new identity
document's key ring. We call this set of trusted keys the project's *delegation*,
and each key is called a *delegate*. Though these will often map one to one with
maintainers, this is not a requirement. The only requirement is that they be
trusted to represent a given project, as they will be used to determine
the canonical state of the project repository.

From this initial identity document we can then derive a unique, stable
identifier for the project, by hashing the document's contents. In addition to
the *delegation*, we include in the document a user-chosen *alias* for the
project, as well as a *description*. The process for hashing the document shall
be discussed in a subsequent RIP.

It is by including the identity document in the *signed refs* that we establish
a relationship between the source code and the identity, and thus associate
the project identifier with the project source code. Note that this permits
identical source codes to have more than one identity. This is useful when
a user wishes to a *fork* a repository. In that case, a new project would
be initialized with a brand new identifier, but a mostly identical source code
history.

The storage, update and verification mechanism for the identity document
will be discussed in more detail in a future RIP. For the purposes of this
document, we can assume a verification mechanism that takes as input the project
identifier, signed refs, and identity document, and outputs whether the project
is valid or not.

At the networking level, all we need is a way to derive stable identifiers for
repositories, and a verification process that asserts that a given repository
corresponds to some project identifier.

Repository Discovery
--------------------
The Radicle network protocol has to serve one core purpose: given a project
identifier, a user should be able to retrieve the full project source code
associated with that identifier, and verify its authenticity. This function
should be independent of where the project is located, and how many replicas
exists, provided at least one replica exists.

### Topology

Given that there is no natural incentive for nodes to host *arbitrary* projects,
nodes on the network should be given the choice of which projects to host.

For example,

* A company that uses or provides open source software may want to host it on
  their node, to ensure its continued availability on the network.
* A business that hosts projects for a fee would need to be able to choose
  which projects it hosts.
* A developer contributing to a project may want to self-host it on his node.

For this reason, we cannot deterministically compute on which node(s)
a given project should be hosted, as is the case with DHTs. Nodes are able
to choose what they host, and therefore the network is fundamentally
*unstructured*. Some nodes may host thousands of projects, while others may
host only one or two. Though there is a benefit to arranging the peer
topology in a certain fashion (eg. to reduce communication overhead), this
cannot be relied on in an untrusted network, and therefore we don't make
these assumptions in the basic protocol either.

### Routing

The general problem of reaching a specific node on the network is usually
known as "routing". Where IP routing tries to route traffic to a certain
IP address, in the Radicle network, we attempt to route requests to
one or more nodes that host a given project; these are called *seeds*
in the context of that project. A seed is a node that hosts and serves
one or more projects on the network.

Routing information is usually stored in a *routing table* that is keyed
by the "target", in our case this is the project identifier:

    RoutingTable = BTreeMap<RepositoryId, Vec<NodeId>>

For each project, we keep track of the nodes that are known to host this
project. Using hashes for project identifiers and IP addresses as node
identifiers, the table might look something like:

    80a2970…        54.122.99.1, 89.2.23.67
    c5e079e…        66.12.193.8, 89.2.23.67, 12.43.212.9
    …

To build the table, nodes gossip information about other nodes, namely *what*
projects are hosted *where*.

Assuming `32 byte` project and node identifiers, an average of `3` nodes
hosting each project, and a million projects, all stored in a binary tree,
we would need only about `244 MB` to store the entire routing table in memory
with no compression:

    project count = 1'000'000
    leaf size = 32 + 32 * 3 = 128 B
    leaves size = leaf size * project count = 128'000'000 B = ~122 MB
    index size = leaf size * (project count - 1) = ~122 MB
    total = 122 MB + 122 MB = ~244 MB

Since this amount of memory is available on commodity hardware, we see
no need to partition the routing table for the time being, and propose
that each node store the entire routing table on disk or in memory.

Node Identity
-------------
The identity of a node on the network is simply the identity of the user
operating the node. To be able to securely verify data authorship, we use
public key cryptography, with the public key being used as the node identifier.
In the case of nodes run by end-users; which is likely most nodes; the
node's secret key is used to create the *signed refs* and optionally to
sign git commits.

The use of the same identity for both network communications and code signing
makes the network more transparent, while allowing nodes to trust each other
based on the code they publish.

For nodes that are run as always-on "servers", the node identity may not be
used for signing code. These *seed* nodes only use their secret keys to
sign gossip messages and establish secure connections.

Gossip
------
We design the Radicle networking layer as a *gossip* protocol. In this proposal,
we go over some of the fundamental types of messages that are sent between
peers over the network. We contend that the core functionality can be achieved
with three message types: *inventory* announcements, *reference* announcements
and *node* announcements. Each fulfilling a distinct role. The exact wire
protocol will be described in a future proposal; this section should serve
as a short introduction to the topic.

### Inventory Announcements

To build their routing table, nodes connecting to the network announce to their
peers what inventory they have, ie. what projects they are seeding.
These announcements are relayed to other connected peers, and so
on until they reach the majority of nodes on the network. Messages that have
already been seen are dropped, to prevent messages from propagating forever.
Gossip messages may be retained by nodes for a certain amount of time, so that
they can be served to new nodes joining the network. The *inventory
announcement* message has the following shape:

    InventoryAnnouncement = (
        NodeId,
        Vec<RepositoryId>,
        Timestamp,
        Signature,
    )

It contains the identifier of the node making the announcement, the inventory
of projects, a timestamp, and the signature of the node over the projects and
timestamp. By using a public key as the `NodeId`, we can then both identify
and verify the provenance of the message, using the signature.

In this manner, every node in the network will eventually converge
towards a single routing table, provided the network is well connected.

For larger networks, where nodes cannot be fully meshed, it's desirable for
seeds that have projects in common to be connected to each other. Hence,
nodes should prioritize connecting to peers that seed the same projects as
them. This is simply because relevant messages can reach interested nodes
more quickly and efficiently if nodes with shared interests are directly
connected to each other; but also because nodes can use already-established
connections to fetch data of interest.

As is often the case with large, unstructured networks, gossip messages can be
received out of order. For this reason, the inventory message includes a
*timestamp*, which is used for ordering messages. Since the inventory message
is meant to communicate a node's complete inventory, nodes can simply ignore
inventory messages with timestamps lower than the latest received, and not
relay them. To mitigate issues with timestamps far in the future, we reject
messages with timestamps too far in the future.

#### Pruning

One worry with routing tables on permissionless networks is that nodes come and
go all the time. While a project may be available on a node one day, the node
may go offline the next day and never come back online. Additionally, nodes
may choose to stop hosting a certain project, making it no longer available.

Hence, the routing table needs to be constantly pruned, with out-of-date
entries evicted. To achieve this, we set an expiry on routing table entries,
and require live nodes to "refresh" their entries on other nodes by sending
`inventory` messages periodically.

Entries that have been in the table for more than a day without updates or
refreshes can then be automatically evicted.

### Reference Announcements

When an update to a project is made by a user, the user's node sends a message
to the network, announcing the update. Nodes that are tracking this project are
then able to fetch the updates via the *git* protocol, either directly from the
user's node, or from an intermediary node. This *refs announcement* message
looks like this:

    RefsAnnouncement = (
        NodeId,
        RepositoryId,
        Map<RefName, CommitId>,
        Signature,
    )

It contains the identifier of the node announcing the updated references, the
repository under which these refs reside, the map of reference names (`RefName`)
with their new commit hashes (`CommitId`) and a signature from the publishing
node (`NodeId`), over the refs and project identifier.

This allows any receiving node tracking the project to verify the legitimacy
of the message using `NodeId` and `Signature`. For new projects, published
on the network for the first time, the same type of message can be used.

Reference announcements, unlike inventory announcement should only be
relayed to interested nodes, ie. nodes that are hosting the given project,
as they will usually be followed by a `git-fetch`.

We should also note that the `NodeId` in this case is not only the announcer
of these updated references, but may be the *author*. When Alice pushes changes
to a project, she announces these changes over the network using a reference
announcement, via her own node.

### Node Announcements

We've touched upon inventory gossip, and how project metadata and data is
exchanged, but not how node metadata is exchanged; or in other words, how *peer
discovery* is carried out. For this purpose, we devise a *node announcement*
message:

    NodeAnnouncement = (
        NodeId,
        NodeFeatures,
        Vec<Address>,
        Timestamp,
        Signature,
    )

This message is designed to be authored by a node announcing *itself* on the
network, and therefore contains a signature and timestamp, and is meant to be
relayed by other nodes on the network. The key "payload" of this message is
the vector of addresses sent by the node. This should contain all addresses
on which the node is publicly reachable. At minimum, this should contain
one IP address, but in the future could contain `.onion` addresses or DNS
names.

As with the inventory message, nodes should buffer these announcements to serve
them to new nodes connecting to the network. In addition to the list of
addresses, we propose to also include a list of features supported by the
announcing node, to allow for future protocol upgrades.

#### Bootstrap Nodes

A node joining the network for the first time will not know of any peers.
Hence, it's advised that network client software be pre-configured with
DNS "seeds". These are registered DNS names, eg. `seeds.radicle.xyz` that
resolve to node addresses on the network. In the bootstrapping process,
nodes can resolve these names to have a set of addresses to initially
connect to, and once they find a peer, use the regular peer discovery
process to find more nodes.

Replication
-----------
While gossip is used to exchange *metadata*, the actual repository *data*, ie.
Git objects are transferred via the process of *replication*.

Nodes are configured with a list of projects that they are meant to host. These
are called *tracked* projects, and this configuration is called the *tracking
policy*.

When a new node joins the network, the first thing it will attempt to do is to
retrieve these tracked projects from the network. This is called *bootstrapping*.
To do this, the node consults its routing table, locates the project's *seeds*,
and initiates a `git-fetch` via the *git* protocol, with one or more seed. This
fetch operation downloads the relevant git objects into the node's *storage*,
making them available to other interested nodes.

To notify its peers that its inventory has changed, it sends an *inventory*
message to each of its peers. Replication is only possible because of the
exchange of information on the gossip layer. Without it, nodes wouldn't
know where to replicate projects from, and would quickly fall behind.

### Project Tracking and Branches

While it's possible to always replicate and track at the *repository* level,
it is highly impractical: such an *open* tracking policy is easily abused by
malicious nodes. Given limited disk space and bandwidth, nodes need a way to
replicate only a *subset* of repository data, authored by users they can
trust.

If we want to allow contributors to publish code that is intended to be merged
into another project, we need to think about a node's tracking policy with
respect to individual contributors and their git reference *trees*
(the set of all branches published under a project by a given contributor).
The safest tracking policy is to only track trees published by the delegates of
a tracked project. But this means that contributors (non-delegates) won't have
their changes replicated on the network. This becomes a problem when a
contributor wants to propose a new patch to a project: unless the contributor
is online to *seed* that branch, there is no way for the maintainer to retrieve
it.

Lacking a good answer to this problem at the protocol level, we defer to node
operators to implement policies at the individual seed level. For example, a
seed node may require of users to link their social profiles with their Radicle
key before enabling tracking for their branches.

In the past, we've explored the idea of a "social" tracking graph. We leave
this door open for potential future iterations of the protocol.

### Unintentional Forks and Conflicts

It is possible, through a software bug or user error to unintentionally fork
one's history. For example, a user publishes changes to a branch that land
on a node in the network, but later re-writes that branch's history and
re-publishes it. Nodes that received the initial changes will not be able
to merge these new changes via a simple history *fast-forward*, while nodes
that never saw the initial changes will have no problem fetching the new ones.

    User       Seed #1       Seed #2

    B                          B
    |  A            A          |
    | /            /           |
    |/            /            |
    |            |             |

In the above diagram, a user publishes history `A` under branch `master`,
which lands on `Seed #1` and then publishes history `B` under the same branch.
`Seed #2`, which didn't have the prior history is able to fetch that branch
without problems. However, `Seed #1` isn't, since the histories are divergent.

Now, depending on which seed is used to fetch, a user would get a completely
different history for that branch.

To solve this problem, we have to realize one simple thing: every time a user
publishes new code to the network, a commit in the *signed refs* history is
created. This means that after publishing `B`, the user's signed refs history
will look like this:

    refs/…/heads/master    B
    refs/…/heads/master    A
    …

Since `Seed #1` will have this history if it fetches `B`, it will be able to
simply set the head of the branch to the latest signed ref for that branch,
which is `B`.

Forks in the signed refs history itself, though much more problematic, could
be recovered by picking the history with the latest timestamp.

Storage
-------
Since storage and replication are tightly coupled, and replication makes use of
Git, so does storage. Unlike previous versions of Radicle, each project is
stored in its own *bare* Git repository, under a common base directory.

Storage is accessed directly by the node to report inventory to other nodes,
and accessed by the end user through either specialized tooling or `git`.

It's important to know that a user working on a project will typically have
*two* copies of the repository: one in storage, called the *stored* copy,
and one *working copy*. The working copy will be setup in such a way that it is
linked to storage via a *remote* named `rad`. Publishing code is then a matter
of running for eg. `git push rad`. Code in storage can be considered *public*,
since it is shared with connected peers, while code in the working copy is
considered *private* until pushed.

This allows for code to be staged for publishing even while offline, provided
the user's storage is accessible. In most cases, it makes sense to keep
storage and working copies on the same machine.

    ┌╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴┐          ┌╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴┐
    ┆ ┌───────────────────┐ ┌──────┐ ┆          ┆ ┌──────┐ ┌─────────────────┐ ┆
    ┆ │ Storage           │ │      │ ┆   Git    ┆ │      │ │ Storage         │ ┆
    ┆ │                   ├╸┆╸╸╸╸╸╸┆╸╸╸╸╸╸╸╸╸╸╸╸╸╸┆╸╸╸╸╸╸┆╸┤                 │ ┆
    ┆ │ ┌──────┐ ┌─────┐ ┌│ │      │ ┆ protocol ┆ │      │ │ ┌─────┐ ┌─────┐ │ ┆
    ┆ │ │repo  │ │repo │ ││ │      │ ┆          ┆ │      │ │ │repo │ │repo │ │ ┆
    ┆ │ ├──────┤ ├─────┤ ├│ │      │ ┆          ┆ │      │ │ ├─────┤ ├─────┤ │ ┆
    ┆ └─┴───╿──┴─┴───┬─┴─┴┘ │      │ ┆          ┆ │      │ └─┴───┬─┴─┴───╿─┴─┘ ┆
    ┆       │        │      │      │ ┆  gossip  ┆ │      │       │       │     ┆
    ┆       │        │      │ Node ├╸╸╸╸╸╸╸╸╸╸╸╸╸╸┤ Node │       │       │     ┆
    ┆       │        │      │      │ ┆ protocol ┆ │      │       │       │     ┆
    ┆      push     pull    │      │ ┆          ┆ │      │      pull    push   ┆
    ┆       │        │      │      │ ┆          ┆ │      │       │       │     ┆
    ┆       │        │      │      │ ┆          ┆ │      │       │       │     ┆
    ┆       │        │      │      │ ┆          ┆ │      │       │       │     ┆
    ┆  ┌────┴───┐ ┌──╽─────┐│      │ ┆          ┆ │      │ ┌─────╽──┐ ┌──┴────┐┆
    ┆  │working │ │working ││      │ ┆          ┆ │      │ │working │ │working│┆
    ┆  │copy    │ │copy    ││      │ ┆          ┆ │      │ │copy    │ │copy   │┆
    ┆  └────────┘ └────────┘└──────┘ ┆          ┆ └──────┘ └────────┘ └───────┘┆
    └╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴┘          └╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴┘

Splitting the storage into per-project repositories has numerous advantages
over previous designs that used a "monorepo":

* Private repositories become possible to offer
* Concurrency is simpler, since we can have locks at the project level
* The Git object database is used more efficiently, since there is more sharing
* Repository settings can be tuned on a per-project level

### Layout

Each project under radicle is stored in a bare Git repository containing
the local user's refs, as well as the refs of all of the peers that the
user's node is configured to track. A simple "namespacing" scheme can be used,
similar to the one used by git for remote tracking branches.

Since nodes replicate Git data from other nodes, a partitioning scheme is
needed to separate references belonging to each node within each project.
This can be achieved by using a node's unique identifier (its public key)
to namespace Git references, since references are by their nature hierarchical.

#### Special References

To store project metadata, special Git references are used. These are references
that are written to a known location that doesn't vary between projects, and in
some cases is meant to be hidden from the user, and accessed only through
purpose-built tooling.

The first one is the head of the project identity branch:

    refs/rad/id

This reference points to the latest version of the identity document. Users
who want to make changes to their project's identity document can checkout
this branch.

The second one is the *signed refs*:

    refs/rad/sigrefs

You'll notice these references are not under the `heads/` hierarchy and therefore
aren't regular branches. These references point to commit histories, though
these histories are disjoint from the source code's history. Since they
determine the outcome of project verification, they need to be handled with
care and are not intended to be accessed directly by an end user.

Storage layout will be specified in more detail in future work.

Canonicity
----------
In the above examples, we limited ourselves to projects with a single delegate.
For the majority of open source projects, this is fitting: a single maintainer
is in charge of the code. However, larger projects often have more than one
user with push access or commit rights. In the Radicle model, there are no
shared branches: each branch or set of branches under a tree is owned by
*one* key. This is why they are partitioned by a public key in the repository
hierarchy.

In a project with multiple delegates, for example, Alice, Bob and Eve, each
would have their *own* `master` branch which only they could write to, eg.:

    <alice>/refs/heads/master
    <bob>/refs/heads/master
    <eve>/refs/heads/master

So how does a contributor know which of those branches is the canonical one?
The protocol itself does not have a notion of canonicity. It is left up to
social consensus: perhaps the three delegates have agreed that Eve's `master`
branch will be the canonical one that everyone should pull from. This agreement
can be encoded in the project's identity document, and leveraged by tooling,
but it is entirely optional, as it may not be desirable for all projects to
"elect" a delegate that way.

For projects that do not have a canonical `master`, there is another option
to establish consensus on the state of a repository: *quorum*. Simply put,
we can examine the commit histories of all three `master` branches, and
pick the *latest* commit included in a *majority* of histories as our canonical
state. For example, in the example below, the commit referred to by `B`, that
is Bob's latest would be used.

    Alice       Bob       Eve

    C o                    D o
      |                     /
    B o        B o       B o <- quorum
      |          |         |
    A o        A o       A o
      |          |         |


Closing Thoughts
----------------
The protocols described above are part of a larger system. It's our hope that
subsequent RIPs will answer some of the questions that arise from this proposal,
as well as flesh out the functionality on top of the base protocol. How to
represent rich social interactions and collaboration such as code review,
comments, issues and patches on top of this protocol, is left for future
discussion.

Credits
-------
* Kim Altintop, for coming up with the original design this protocol is based on
* Alex Good, for helping iterate on some of the ideas found in this proposal
* Fintan Halpenny, for helping iterate on some of the ideas found in this proposal

Copyright
---------
This document is licensed under the Creative Commons CC0 1.0 Universal license.
