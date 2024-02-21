---
title: Radicle User Guide
subtitle: A fantastic journey through the Radiverse
layout: guide
---

Software is *the* fundamental way in which we interface with data that
comprises our current reality, and code is the language of software. Most
software systems were created through a collaborative process involving
multiple people. If we accept that software is important and collaborative by
nature, then a shared system for communicating about code and collaborating is
needed. This system shouldn't be owned by one company, as code is too important
to be monopolized.

<aside class="span-2">
  <p> Microsoft acquired GitHub in 2018. They also own 49% of OpenAI. One of
  our prophets of the future, the author Philip K. Dick, has shown us many
  projections of alternate dystopian realities that emerge when corporations
  amass too much power. </p>
  <p> While some may question the reliability of his visions as
  he was often fueled by substances that would make even psychonauts raise an
  eyebrow, consider this: the Oracle at Delphi's officiant claimed to glimpse
  through the veil by inhaling naturally occurring gasses emerging from the
  ground. </p>
</aside>

Furthermore, our world is increasingly polarized, and this reality is finding
its way into software companies and therefore into software products. Users are
banned from using a platform because of their geographic location or the ideas
they stand for. This is not tenable.

This is why we’ve created Radicle, an open protocol that enables users like you
to collaborate on your code within a sovereign network. It's a neutral
environment where you have full ownership of your data and you have the
autonomy to set the rules of your code universe as you see fit. You can work on
software projects (and ultimately more) even when offline, while also being
connected to a broader network, through which you'll eventually be able to find
contributors.

We've created this Radicle Guide to initiate you as a settler of our network
through teaching you how to use the software we've developed—the Radicle
CLI, which is both a node and command line interface tool for interacting with
the protocol. This guide is split into multiple chapters and we recommend
starting with the first chapter for a higher level introduction that takes you
on a tour through Radicle's core functions. Subsequent chapters will provide
deeper dives into specific use cases, but they are still in progress.

> 👾
>
> Greetings! If you ever get stuck and want additional guidance, join us in our
> [chatroom][zulip] on Zulip and ask your questions in the `#support` channel.
>
> Also, this guide teaches you how to use Radicle in a narrative fashion. If
> you're looking for more straightforward usage docs, check out the Radicle
> manual or the [Protocol Guide][proto] for more information on Radicle's
> fundamental building blocks and motivations.
>
> Oh! And allow me to introduce myself. My name is `paxel` and every once in a
> while you may see me in this guide, interjecting with hot tips like this.

<aside> The Radicle manual can be accessed by entering <code>man
rad</code> from your command line, after installing Radicle. </aside>

## 1. Getting Started

One of the important facts to understand about Radicle is that it is a
peer-to-peer protocol, which is uncommon when it comes to software you
typically rely on. Most collaboration technologies are hinged upon a
client-server model, where you're entrusting your data and social interactions
to a single entity that is managing a bunch of servers or data centers. This
paradigm is transformed in a peer-to-peer protocol, where every user of the
protocol is a *peer*, participating equally. Peers on the Radicle network are
also referred to as **nodes**, and it doesn't matter what you are doing --
whether you're publishing repositories or discussing issues -- you have to run
a node.

Within a few paragraphs, you'll be operating a Radicle Node via the command
line by installing the Radicle software stack. It's a pretty easy process that
can be completed in under 5 minutes, but there are a few requirements that are
important to run through before you proceed:

1. You need a <strong>Linux</strong> or <strong>Unix</strong> based operating
   system like macOS or Ubuntu and a basic understanding of how to use your
   terminal.
2. Radicle is built on top of <strong>Git</strong>, so a recent version of Git
   (2.34.0 or later) is recommended. We also assume you have *some* experience
   using Git.
3. OpenSSH (version 9.1 or later) with <strong>ssh-agent</strong> has to also
   be installed and running. This is a helper program that is used to secure
   the secret key related to your Radicle identity.

<aside> What is <strong>Git</strong>, you wonder? <a
href="https://en.wikipedia.org/wiki/Git">Git</a> is a distributed version
control system that manages and tracks changes in computer files, predominantly
used for source code and collaborative programming. </aside>

> 👾
>
> You can check your git and ssh installations by running `git
> --version` or `ssh -V` in your terminal.
>
> If you haven't used Git before, you're going to be in a world of pain and
> should read through the [Pro Git][pro-git] book first.

[pro-git]: https://git-scm.com/book/en/v2

### Installation

The easiest way to install Radicle is by firing up your terminal and running
the following command:

    $ curl -sSf https://radicle.xyz/install | sh

This command runs an installer script that automates the setup process, by:

* Identifying your OS, and installing Radicle binaries suitable for your
  system, including `rad`, `git-remote-rad`, `radicle-node`, and
  `radicle-httpd`, all placed in `~/.radicle/bin` by default. This is a
  non-standard location, so the script also updates your `PATH` variable to
  include the path to these binaries.
* Installing `man` pages into `~/.radicle/man`, which enables you to access
  the Radicle CLI user manual through `man rad` or `rad help`.

> 👾
>
> If you want the above to be installed in a different
> location than `~/.radicle`, you can set the `RAD_PATH` environment variable
> before running the installation script.
>
> Note that if you don't want to use the installer script, you can also always
> compile from the [source code][heartwood] or get the [binaries][] if you
> prefer.

[heartwood]: https://app.radicle.xyz/seeds/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5
[binaries]: https://files.radicle.xyz/latest/

Once you've installed Radicle, you can make sure that it was successful by
running:

    $ rad --version
    rad 1.0.0

### Come Into Being From the Elliptic Aether

When using Radicle for the first time, you have to create a new Radicle
identity, which is simply a cryptographic key pair, using the `rad-auth`
command. The public key is what uniquely identifies you across the network,
while the private key is used to authenticate your node, as well as sign code
and other artifacts you publish on the network.

<aside class="span-5">
  <p><strong>🧠 Learn more</strong></p>

  <p> A cryptographic key pair is a set of two keys used in cryptography,
  typically for securing digital communication and data.</p>

  <p> The pair consists of a public key and a private (or secret) key. The
  public key can be shared with others and is used to encrypt data or verify
  digital signatures created with the corresponding private key. Conversely,
  the private key is kept secret by the owner and is used to decrypt data
  encrypted with the public key or to create digital signatures. </p>

  <p> The use of these keys ensures authenticity, as digital signatures can
  confirm that a message or data was indeed sent by the owner of the private
  key. </p>
</aside>

    $ rad auth

That's how you'll cryptographically forge your new Radicle identity.

Follow the instructions by entering an **alias**, a non-unique name that makes
it easier to identify your node, in addition to a **passphrase** to protect
your key pair. Note that your alias can always be changed at a later time.

    $ rad auth

    Initializing your radicle 👾 identity

    ✓ Enter your alias: paxel
    ✓ Enter a passphrase: ********
    ✓ Creating your Ed25519 keypair...
    ✓ Adding your radicle key to ssh-agent...
    ✓ Your Radicle DID is did:key:z6Mkhp7VUnuufpvuQ3PdysShAjL86VDRUpPpkesqiysDBGs9. This identifies your device. Run `rad self` to show it at all times.
    ✓ You're all set.
    ...

When you've completed the steps, your new Radicle DID (Decentralized
Identifier) will be generated and displayed. The Radicle DID is a
[self-sovereign][ssi] identity you have full control over. If `ssh-agent` is
running, your private key will also be added to it for future use.

<aside class="span-4">
  <p><strong>DIDs</strong> are a new identifier standard established by the W3C
  that are used for interoperability across various systems and provide
  flexibility for incorporating different types of identifiers in the
  future.</p>

  <p><strong>Ed25519</strong> is a public-key signature system that uses a
  variant of the Schnorr signature based on Twisted Edwards curves. It's known
  for its speed, security, and efficiency, and is used in applications like SSH
  authentication, TLS encryption, and software package verification.</p>
</aside>

[ssi]: https://en.wikipedia.org/wiki/Self-sovereign_identity

<aside class="span-4 kicker">
  <p><strong>🧠 Learn more</strong></p>

  <p> <code>ssh-agent</code> is a helper program that manages your SSH keys
  and passphrases, encrypting the keys with your passphrase for secure
  storage.</p>

  <p>Once the keys are loaded into the agent, it can use them to authenticate
  your access to Radicle and sign data, eliminating the need to re-enter your
  passphrase.</p> <p>Use <code>ssh-add -l</code> to view the keys the agent
  currently holds. For further details, visit the
  <a href="https://www.ssh.com/academy/ssh/agent">website</a>. </p>
</aside>

If you run `rad auth` again you can verify that your key was added to
`ssh-agent`.

    $ rad auth
    ✓ Radicle key already in ssh-agent

> Your Radicle DID is similar to your Node ID (NID), the difference is the
> former is formatted as a [Decentralized Identifier][did], while the latter is
> just the encoded public key. Share your Radicle DID freely with
> collaborators.

If you forget your DID or NID, you can query your full identity by running `rad
self` or alternatively you can grab your DID with `rad self --did` and your NID
with `rad self --nid`.

```
$ rad self
Alias           paxel
DID             did:key:z6Mkhp7VUnuufpvuQ3PdysShAjL86VDRUpPpkesqiysDBGs9
└╴Node ID (NID) z6Mkhp7VUnuufpvuQ3PdysShAjL86VDRUpPpkesqiysDBGs9
SSH             running (3817)
├╴Key (hash)    SHA256:YCmRe6BkDOp45lYg0m5DeYxgRcPKftQZb4RmQD1nkjQ
└╴Key (full)    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9xo9DHlsZJeZWnZaaawsnKFjcQxN4LQ…
Home            /home/paxel/.radicle
├╴Config        /home/paxel/.radicle/config.json
├╴Storage       /home/paxel/.radicle/storage
├╴Keys          /home/paxel/.radicle/keys
└╴Node          /home/paxel/.radicle/node
```

This displays your alias, DID, Node ID, SSH agent status, SSH keys, and the
locations of important files or directories.

> 👾
>
> Many of the other items you see in the `rad self` output can be viewed
> individually. Wondering about your alias? A quick `rad self --alias` has you
> covered. Need to pinpoint your Radicle home folder? `rad self --home` is your
> friend. And for your config file location, just hit up `rad self --config`.
>
> If you're ever feeling lost, `rad self --help` will lay out all your options.

### Operate Nodes, Smoothly

Now that your node has an identity (or 'public key'), you have what it takes to
connect to the Radicle Network. That's right -- we don't need your email
address or any other personal identifying information. Your alias can be your
cat's name for all we care.

The first command to embed deep within your consciousness is the one for
checking your node's status:

    $ rad node status

If the node is not running, you can start it as a background daemon with:

    $ rad node start

After your node starts, it will attempt to connect to peers on the network.

But let's take a step back and ponder some fundamental questions: *What exactly
happens when these nodes interact? And how does Git fit into this picture?*

At its core, Radicle marries Git with peer-to-peer networking. Your node isn't
just another cog in the machine; it's a conduit for collaboration. It's there
*to host and synchronize repositories you're interested in*.

Radicle's peer-to-peer architecture draws inspiration from [Secure
Scuttlebutt's][ssb] gossip protocol where data transmission relies on a
publish/subscribe system, allowing peers to host and sync only the data they
care about. Similar to [BitTorrent][bt], we use the terminology "seeding" to
describe distributing and sharing a repository across the network.

With Radicle's gossip protocol, peers exchange messages about the network that
facilitate the discovery and replication of repositories. The replication
process kicks off when a node establishes a secure connection with another
node, the initiating node conducts a *fetch* operation via the Git protocol to
pull the pertinent objects into the node's storage, thereby availing them to
the local user and other interested nodes.

<aside> <strong>Replication</strong> is the process of creating multiple copies
<em>(replicas)</em> of data across a network of peers to ensure redundancy,
improve reliability and enhance access speed. </aside>

> If you're curious about how Radicle works under the hood, read our
> [Protocol Guide][proto].

### Git Going With Repositories

Now, time to return to your terminal. The next thing we'll do is publish a
repository to the Radicle network. Once we've done this, anyone with a node
will be able to fetch and seed your repository, increasing its replica count
on the network.

<aside class="span-3"> We built Radicle on good old Git, the go-to for version control
because, well, it is widely used and works extremely well. For a zeptosecond,
we considered inventing a new system but heard a strong shout in our brains
that said something like "YOU'D BE SO STUPID TO REINVENT VERSION CONTROL RIGHT
NOW". </aside>

Pick a repository you maintain and navigate to a local copy. It can be any Git
repository, but it should have at least one commit.

    $ pwd
    /home/paxel/src/dark-star-data

    $ git status
    On branch master
    Your branch is up to date with 'origin/master'.
    nothing to commit, working tree clean

To publish it to the Radicle network, run the `rad init` command.

    $ rad init

    Initializing radicle 👾 project in .

    ✓ Name: dark-star-data
    ✓ Description: Decoding data from the dark star to establish a model of the universe
    ✓ Default branch: main
    ✓ Visibility: public
    ✓ Project dark-star-data created.

    Your project's Repository ID (RID) is rad:z31hE1wco9132nedN3mm5qJjyotna.
    You can show it any time by running `rad .` from this directory.

    ✓ Project successfully announced to the network.

    Your project has been announced to the network and is now discoverable by peers.
    You can check for any nodes that have replicated your project by running `rad sync status`.

    To push changes, run `git push`.

Don't be afraid to do this on one of your existing public repositories! Because
even if you aren't ready to use Radicle for code collaboration, it works great
for distribution where you can establish a more decentralized "mirror" of your
code, so to speak. A mirror that is *censorship resistant, sovereign,
tamperproof, ungovernable -- except by you, and oh so magical*. What `rad init`
does is gather the essential details from you which are needed to initialize
the repository into Radicle: the repository name, description, default branch
(typically `main` or `master`), and whether it is public or private.

Similar to how `git init` is used to initialize a Git repository, we use
nomenclature you're familiar with so you don't go crazy. That'd be so cruel if
you had to do `rad new`, instead, wouldn't it?

> It's important to only publish repositories you own or are a maintainer of,
> and to communicate with the other maintainers so that they don't initialize
> redundant repository identities.

After entering your repository details, you're presented with a Repository
Identifier (RID) that is a globally unique URN that you can share with your
collaborators or friends so that they can clone or seed your repository.
Besides generating the RID, `rad init` creates a special Git remote in your
working copy named `rad` and publishes the repository to the network (assuming
it's public). We'll talk more about private repositories in another chapter.

<aside class="span-2">
  <p><strong>🧠 Learn more</strong></p>

  <p>A Uniform Resource Name (URN) is a type of Uniform Resource Identifier (URI)
  that is used to uniquely identify resources without specifying the location
  or means to access them. Unlike URLs, which provide information on where a
  resource can be found on the Internet (their location), URNs serve as
  persistent, location-independent resource identifiers.</p>
</aside>

<aside class="kicker">
In Radicle, a <strong>delegate</strong> refers to a role or entity that has
been granted the authority to sign for and manage a repository and its metadata.
</aside>

When you initialize a repository you are the sole maintainer or *delegate*, the
term used in Radicle. Delegates can represent a group, person or even a bot. In
your case, I'm assuming you're a person. Delegates can be added or removed from
a repository, by existing delegates. We'll talk about this more in one of the
next chapters.

> 👾
>
> A few hot commands you might want to know about, that can be run within a
> repository you've initialized:
>
> * It's difficult to memorize RIDs. Use `rad .` to display the current
>   repository's RID.
> * To display the repository's identity payload, which contains its name,
>   description and default branch, run `rad inspect --payload`.
> * To make updates to the repository identity, including its visibility, check
>   out `rad id --help` for further instructions.

Note that your new repository will only be replicated by nodes that you are
connected to and either have an open seeding policy, or follow you. Seeding
involves both hosting the repository and synchronizing changes with other
nodes. In the early stages of the Radicle network, all public repositories are
automatically seeded by `seed.radicle.garden` which is a *public seed node*
run by the core team.

<!-- TODO: Talk about seeding policies and following -->

<aside class="span-2"> <strong>Seed nodes</strong> are always-on machines that
significantly enhance the network’s capacity to provide continuous access to
repositories. They can vary in their seeding policies, from public seed nodes
like <code>seed.radicle.garden</code> that openly seed all repositories, to
community seed nodes that selectively seed repositories based on rules
established by their operators. </aside>

You don't *have* to trust or rely on our public seed node. You can run
your own. As more people run them, Radicle becomes more resilient and
reliable for code collaboration.

> We are always looking to attract more people
> that want to operate public seed nodes: if that's you, check out our
> [Seeder's Guide][seeder] for more details.

### Publishing *ch-ch-ch-ch-changes*

<div class="poem"> Still don't know what I was waiting for<br/> Requiring an
internet connection to push to remote<br/> But now I push to my local-first, oh so
`rad` remote<br/> Instead of that one shoddy monopolized forge </div>

As we just mentioned, `rad init` creates a special remote in your working copy
named `rad`. What's this doing under the hood? With Radicle, you will typically
be interacting with two different repository copies on your device, the
*working copy* and a hidden, *stored copy* that you interact with via `git push
rad` and `git pull rad` commands using Radicle's *git remote helper* program
named `git-remote-rad`. Remote helpers are particularly useful for integrating
Git with specialized network protocols like Radicle. Git calls the custom
`git-remote-rad` program when it encounters `rad://` remotes.

> **🧠 Learn more**
>
> Git remote helpers are custom programs that allow Git to interact with
> repositories hosted on various types of servers or protocols that are not
> natively supported. Remote helpers are invoked by Git when it encounters a URL
> scheme that matches a supported helper. For example, in Radicle's use case, if
> Git sees a URL starting with `rad://`, it will look for a remote helper program
> named `git-remote-rad` and use this program to handle operations related to
> that URL, such as fetching, pushing, and cloning. For more details, check out
> Git's [documentation](https://git-scm.com/docs/gitremote-helpers) on remote
> helpers.

To view information about the `rad` remote in your repository, try:

    $ git remote show rad
    * remote rad
      Fetch URL: rad://z31hE1wco9132nedN3mm5qJjyotna
      Push  URL: rad://z31hE1wco9132nedN3mm5qJjyotna/z6MkvZwzK64f3GuDcAs6dEcje89ddfHkBjS1v9Dkh7aCGq3C
      HEAD branch: (unknown)
      Remote branch:
        main tracked
      Local branch configured for 'git pull':
        main merges with remote main
      Local ref configured for 'git push':
        main pushes to main (up to date)

You'll notice the Repository ID in a URL format under `Fetch URL`:

    rad://z31hE1wco9132nedN3mm5qJjyotna

For the `Push URL`, you may be wondering, what is the element after the slash?

    z6MkvZwzK64f3GuDcAs6dEcje89ddfHkBjS1v9Dkh7aCGq3C

Does it look familiar to you? Well, it's your Node ID. Remember you can always
check your Node ID by running `rad self --nid`.

When using Git with traditional forges, you are pushing to a remote which is a
centralized server that all other collaborators are also using. In Radicle, the
remote is on your local device, which means that you can push changes even when
you're disconnected from the internet. Changes that you push to the remote
while offline will automatically propagate to the network once you come back
online. This is one of the very unique aspects of Radicle that makes offline
work *way smoother*.

<aside>
 When using GitHub, for example, you will be pushing to a remote URL that
 starts with <code>https://github.com/</code>, followed by an account and
 repository name. On Radicle, the URL you push to does not represent a specific
 host, it represents a de-centralized repository, identified by name only, not
 location.
</aside>

> **🧠 Learn more**
>
> Radicle's storage layout accommodates multiple source trees *(forks)* per
> repository. Each repository is stored as a bare Git repository, residing under
> a common base directory, uniquely identified by its Repository ID (RID). Rather
> than storing peer data in separate Git repositories with individual object
> databases (ODBs), Radicle consolidates peer data within the same Git
> repository. This is achieved using the `gitnamespaces` feature, where each
> peer's unique Node ID serves as a namespace to partition their Git references.
>
> See the [storage](/guides/protocol#local-first-storage) section of the
> protocol guide for more information.

Now let's try publishing some changes to see how this works.

Use your favorite text editor to make a change to the repository that you just
initialized. For example, you can update its README to include instructions on
how to clone the repository on Radicle:

    $ git diff
    diff --git a/README.md b/README.md
    index 91b304791..70ef6efc9 100644
    --- a/README.md
    +++ b/README.md
    @@ -58,6 +58,12 @@

    +## Radicle
    +
    +To clone this repository on [Radicle](https://radicle.xyz), simply run:
    +
    +    rad clone rad:z31hE1wco9132nedN3mm5qJjyotna
    +

Once you're finished, add and commit your changes with `git add` and `git
commit` just as you would when collaborating on any other Git repository. Then
use `git push rad master` to synchronize the changes with your node (be sure to
replace `master` with your default branch, in case that's not it).

    $ git add README.md
    $ git commit -m "Add instruction on cloning with Radicle"
    $ git push rad master
    ✓ Synced with 1 node(s)
    To rad://z31hE1wco9132nedN3mm5qJjyotna/z6MkvZwzK64f3GuDcAs6dEcje89ddfHkBjS1v9Dkh7aCGq3C
       ecb1bf0..74fb8d2  master -> master

Whenever you execute a `git push rad` command, you are pushing the changes in
your local working copy to your remote copy. You see that the remote of your
repository is represented by the URL:

    rad://z31hE1wco9132nedN3mm5qJjyotna/z6MkvZwzK64f3GuDcAs6dEcje89ddfHkBjS1v9Dkh7aCGq3C

As the sole delegate of the repository, changes that you push to the
repository's default branch under the `rad` remote, represent the **canonical**
or *authoritative* state of the repository. This means that if someone were to
clone your repository, they would be getting the state that you just pushed,
given your nodes are able to communicate with each other.

> **🧠 Learn more**
>
> The canonical repository state is established *dynamically* based on the
> delegate thresholds defined for the repository. For example, if a `threshold`
> of two out of three delegates is set, with the `defaultBranch` specified as
> `main`, and both Alice and Bob have the same commit in their `main` branches,
> that specific commit is recognized as the authoritative, current state of the
> repository. In the current Radicle release, the dynamic establishment of an
> authoritative state is limited to a single `defaultBranch`. Future releases
> of the protocol may enhance this feature to include additional secondary
> branches.

You may be wondering -- now that you've pushed to your remote, how do other
peers get this update? Any peer who has cloned or seeded the repository will
receive a *reference announcement* message from its peers, via the gossip
protocol, which informs the node there was an update. Following this, peers
conduct a *fetch* operation via the Git protocol to pull the pertinent Git
objects into their local storage.

### The Basics of Seeding and Cloning

Nodes have a *seeding policy* which specifies the list of repositories they are
interested in replicating on the network.

Whenever you clone or initialize a new repository, your node's seeding policy
is updated to keep these repositories in sync with the network.

There are a few ways that seeding relationships are established among nodes.
One of the main methods is by one node intentionally *cloning* another
repository. You can run the `rad clone` command to clone a repository from the
Radicle network, by supplying a Repository Identifier (RID).

Let's try this out. First, navigate to a directory where you typically clone
Git repositories. Then run this command to clone the Radicle
[Heartwood][heartwood] repository:

<aside class="span-2"> Heartwood is the name of the current version of the
Radicle protocol. An alpha version was initially released in April 2023.
</aside>

    $ rad clone rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5
    ✓ Seeding policy updated for rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 with scope 'all'
    ✓ Fetching rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 from z6Mkk4R…SBiyXVM..
    ✓ Fetching rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 from z6Mksmp…1DN6QSz..
    ✓ Fetching rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 from z6MkrLM…ocNYPm7..
    ✓ Creating checkout in ./heartwood..
    ✓ Remote cloudhead@z6MksFqXN3Yhqk8pTJdUGLwATkRfQvwZXPqR2qMEhbS9wzpT added
    ✓ Remote-tracking branch cloudhead@z6MksFqXN3Yhqk8pTJdUGLwATkRfQvwZXPqR2qMEhbS9wzpT/master created for z6MksFq…bS9wzpT
    ✓ Repository successfully cloned under /home/paxel/src/heartwood/
    ╭────────────────────────────────────╮
    │ heartwood                          │
    │ Radicle Heartwood Protocol & Stack │
    │ 8 issues · 14 patches              │
    ╰────────────────────────────────────╯
    Run `cd ./heartwood` to go to the project directory.

Cloning has some similarities to Git's `clone` command, in that it creates a
working copy of a remote repository, but this is executed in a much different
way since Radicle is a peer-to-peer protocol.

The `rad clone` command is essentially equivalent to running these lower-level
commands:

| **`rad seed`**       | Updates your seeding policy to start seeding this repository
| **`rad sync -f`**    | Fetches the latest repository data from other seeds and stores it in your local storage
| **`rad checkout`**   | Creates a working copy of the repository from local storage
| **`rad remote add`** | Creates a Git remote in your working copy for all repository delegates

When you only want to *seed* a repository and have no interest in contributing
code, you can still be a repository's friend with the `rad seed` command. This
is Radicle's version of a ⭐ *star* or 👍 *like*, where you show a repository
some real love and care by sharing it with others on the network.

<aside>
  Seeding a repository is a great way of supporting and giving back to a
  project you care about or use. By offering a little bandwidth to the network,
  you ensure the continued availability of the repository to others. ❤️
</aside>

This works similarly to cloning, where the RID is provided, the main difference
is that it doesn't create a working copy.

    $ rad seed rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5
    ✓ Seeding policy updated for rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 with scope 'all'
    ✓ Fetching rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 from z6Mkk4R…SBiyXVM..

When you seed a repository, it updates your seeding policy to subscribe to
updates. It fetches a copy of the repository under your local storage, and
provides a replica to the network.

In the future, if you change your mind and decide that you want to contribute
code to a repository you're seeding, you can always run `rad checkout` to
create a working copy of the repository from local storage and `rad remote add`
to create remotes of peers that you can pull from and push to.

If on the other hand you want to stop seeding a repository, simply run `rad
unseed`. For example:

    $ rad unseed rad:z9DV738hJpCa6aQXqvQC4SjaZvsi

You can list all of your seeded repositories with the `ls` sub-command:

    $ rad ls --seeded

If on the other hand you only want to see repositories you've contributed to in
some way, for example by pushing a branch or commenting on an issue, simply run
`ls` with no arguments:

    $ rad ls

> **👾 Rad Tip**
>
> The set of peers that are followed in the context of a seeded repository
> is called the *scope*.
>
> By default, when cloning or seeding a repository, your node will subscribe to
> content from _all_ peers. This behavior is part of the seeding policy and can
> be changed by passing `--scope followed` to the `seed` and `clone` commands,
> to only subscribe to content from the repository *delegates* plus any node
> that is explicitly followed via `rad follow`.
>
> If a repository wasn't initially cloned or seeded in this way, it can also be
> changed later via the `rad seed` command, e.g.
>
>     rad seed rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 --scope followed
>
> Conversly, to reset it to the default, `--scope all` can be passed.

This marks the end of our initial foray into Radicle. As we move forward to
Chapter 2, we'll dissect the collaborative mechanisms at play, exploring
issues and patches from the unique perspectives of both contributors and
delegates. It's here that the true kernel of *code collaboration* begins to
unfold.

[proto]: /guides/protocol/
[seeder]: /guides/seeder/
[zulip]: https://radicle.zulipchat.com/
[did]: https://en.wikipedia.org/wiki/Decentralized_identifier
[ssb]: https://en.wikipedia.org/wiki/Secure_Scuttlebutt
[bt]: https://en.wikipedia.org/wiki/BitTorrent
[heartwood]: https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5

