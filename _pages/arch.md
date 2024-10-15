---
title: Radicle Architecture
subtitle: An overview of Radicle components
layout: page
variant: wide
---
These are simple architecture diagrams of Radicle. They're meant to
explain what the major components are and how they interact, at a very
high level of abstraction. The goal is to enable you to learn details
from other documentation, not to explain details here.

# Component diagrams

## Level 0: Radicle network

This diagram shows the very topmost level of abstraction showing the
Radicle network of nodes.

* The core component of Radicle is the node. Each Radicle user runs at
  least one node. Nodes connect to each other to synchronize changes
  and other information, to form the Radicle network.
* Each Radicle user uses the `rad` command line tool, or other tools, to
  administer and interact with their local node. They use the local node
  as a Git server, so they push and pull to it from their local working
  tree.
* A Radicle node can also be used as a read-only Git server using a
  normal Git implementation.
* Public repositories on Radicle nodes can be browsed via the Radicle
  explorer application, using a web browser.

<figure class="diagram">
  <object type="image/svg+xml" data="/assets/images/arch-level-0.svg"></object>
  <figcaption>Level 0 architecture.</figcaption>
</figure>


## Level 1

This diagram shows how parts of Radicle running on a node interact.

* Node storage (typically in `~/.radicle/storege`) is where the Git
  repositories the node stores are located. This also stores copies of
  the repositories as they exist on other nodes.
* The `radicle-node` process synchronizes storage with other nodes.
* The `radicle-httpd` process provides read-only access to the public
  repositories in the node storage, for the Radicle explorer. For
  external explorers, the node must have a public IP address.
* The Git helper for Radicle, `git-helper-rad`, allows the Git client
  to interact with node storage via the file system. It also notifies
  the `radicle-node` process when it has made changes to storage.
* The user uses the `rad` command line tool, or another Radicle
  client, to interact with the node and its contents, e.g, to open or
  manage issues and patches.

<figure class="diagram">
  <object type="image/svg+xml" data="/assets/images/arch-level-1.svg"></object>
  <figcaption>Level 1 architecture</figcaption>
</figure>


# Sequence diagrams

This chapter contains some simplistic sequence diagrams for various
operations involving Radicle.

## Add repository to node storage

In other words, seeding a repository by first retrieving it from
another node.

<figure class="diagram">
  <object type="image/svg+xml" data="/assets/images/arch-seq-repo-to-storage.svg"></object>
  <figcaption>Seeding a remote repository</figcaption>
</figure>

## Check out repository from node storage

<figure class="diagram">
  <object type="image/svg+xml" data="/assets/images/arch-seq-checkout-repo.svg"></object>
  <figcaption>Checking out a  repository</figcaption>
</figure>

## Push to node storage

<figure class="diagram">
  <object type="image/svg+xml" data="/assets/images/arch-seq-push-to-storage.svg"></object>
  <figcaption>Push to node storage</figcaption>
</figure>
