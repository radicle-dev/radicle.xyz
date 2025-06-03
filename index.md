---
title: "Radicle: the sovereign forge"
layout: index
---

> ✨ Radicle 1.2 is out. Read the [announcement](/2025/06/02/radicle-1.2.html).

# Synopsis

Radicle is an open source, peer-to-peer code collaboration stack built on Git.
Unlike centralized code hosting platforms, there is no single entity
controlling the network. Repositories are replicated across peers in a
decentralized manner, and users are in full control of their data and workflow.

<a class="screenshot" href="https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5" target="_blank" title="Heartwood is the latest generation of the Radicle protocol">
  <img class="screenshot" src="/assets/images/web-app-screenshot.png"/>
</a>
<small class="caption">
  The Radicle <code>heartwood</code> repository. Repository ID
  <code>rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5</code>.
</small>

<a id="get-started"><!-- Anchor --></a>

# Get started

{% include latest-release.html %}

To install Radicle, simply run the command below from your shell, or go to the
[download][] page.

{% include install.html %}

Alternatively, you can build from [source][heartwood].

For now, Radicle only works on Linux, macOS and BSD variants.

<a class="button" href="/guides/user">Follow the guide &rarr;</a>

# How it works

The Radicle protocol leverages cryptographic identities for code and social
artifacts, utilizes Git for efficient data transfer between peers, and employs
a custom gossip protocol for exchanging repository metadata.

<a class="button" href="/guides/protocol">Learn more &rarr;</a>

## Your Data, Forever and Secure

All social artifacts are stored in Git, and signed using public-key
cryptography. Radicle verifies the authenticity and authorship of all data
for you.

## Unparalleled Autonomy

Radicle enables users to run their own nodes, ensuring censorship-resistant
code collaboration and fostering a resilient network without reliance on
third-parties.

## Local-first

Radicle is [local-first][], providing always-available functionality even
without internet access. Users own their data, making migration, backup, and
access easy both online and offline.

## Evolvable & Extensible

Radicle's [Collaborative Objects][cobs] (COBs) provide Radicle's *social
primitive*. This enables features such as issues, discussions and code review
to be implemented as Git objects. Developers can extend Radicle's capabilities
to build any kind of collaboration flow they see fit.

## Modular by Design

The Radicle Stack comes with a CLI, web interface and TUI, that are backed by
the Radicle Node and HTTP Daemon. It's modular, so any part can be swapped out
and other clients can be developed.

<pre class="diagram">
┌─────────────────┐┌────────────────┐
│  Radicle CLI    ││ Radicle Web    │
└─────────────────┘└────────────────┘
┌───────────────────────────────────┐
│  Radicle Repository               │
│ ┌────────┐ ┌────────┐ ┌─────────┐ │
│ │  code  │ │ issues │ │ patches │ │
│ └────────┘ └────────┘ └─────────┘ │
├───────────────────────────────────┤
│  Radicle Storage (Git)            │
└───────────────────────────────────┘
┌────────────────┐┌─────────────────┐
│  Radicle Node  ││  Radicle HTTPD  │
├────────────────┤├─────────────────┤
│    NoiseXK     ││   HTTP + JSON   │
└────────────────┘└─────────────────┘
</pre>

<a class="button" href="https://app.radicle.xyz/nodes/seed.radicle.xyz">Browse our repositories ↗</a>

# Contributing

Radicle is *free and open source* software under the MIT and Apache 2.0
licenses. Get involved by [contributing code][contribute].

[contribute]: https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/tree/CONTRIBUTING.md

# Updates

**Follow us** on 🐘 [Mastodon][mast], 🦋 [Bluesky][bsky] or 🐦 [Twitter][twitter] to stay
updated, or join our community on 💬 [Zulip][zulip].

- 02.06.2025 [Radicle 1.2](/2025/06/02/radicle-1.2.html) released. ✨
- 05.12.2024 [Radicle 1.1](/2024/12/05/radicle-1.1.html) released. ✨
- 10.09.2024 [Radicle 1.0](/2024/09/10/radicle-1.0.html) is out.
- 26.03.2024 [Radicle 1.0.0-rc.1][1.0] released.
- 10.03.2024 New Radicle homepage.
- 05.03.2024 [Radicle Guides](/guides) launch.
- 05.03.2024 [Radicle makes it to the top of Hacker News][hn]!
- 18.04.2023 [Radicle heartwood is announced](https://x.com/radicle/status/1648336186862194693?s=20).

[hn]: https://news.ycombinator.com/item?id=39600810
[1.0]: https://twitter.com/radicle/status/1772659708978991605

# Feedback

If you have feedback, join our [Zulip][zulip] or send us an email at
[feedback@radicle.xyz](mailto:feedback@radicle.xyz). Emails sent to this
address are automatically posted to our [#feedback](https://radicle.zulipchat.com/#narrow/channel/392584-feedback)
channel on Zulip.

                                                 .


                                                       *
                            .
                  *                              --O--
                                                  /|\
                     ,                     .
                                               .
    ..-.--*--.__-__..._.--..-._.---....~__..._.--..~._.---.--..____.--_--'`_---..
           -.--~--._  __..._.--..~._.--- - -.____.--_--'`_---..~.----_~

                                        .--..~._
                      -.-
                                     .-.        .


[install-script]: /install
[twitter]: https://twitter.com/radicle
[bsky]: https://bsky.app/profile/radicle.xyz
[mast]: https://toot.radicle.xyz/@radicle
[zulip]: https://radicle.zulipchat.com
[heartwood]: https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5
[cobs]: /guides/protocol#collaborative-objects
[local-first]: https://www.inkandswitch.com/local-first/
[download]: /download
