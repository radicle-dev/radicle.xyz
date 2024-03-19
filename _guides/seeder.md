---
title: Radicle Seeder's Guide
subtitle: How to run a Radicle seed node
banner: 24.medium.png
layout: guide
---

To seed is to give back. By seeding repositories on the Radicle network, you
offer bandwidth, storage, and data availability to Radicle users.

In this guide, we'll go through the various steps required to set up a Radicle
*seed node* on a Linux system. Seeding only requires an internet
connection, a public, static IP address, and modest hardware.

We'll cover public seed nodes with an *open* seeding policy, as well as
community seed nodes with more *selective* policies.

Introduction
------------

The term *seed node* originally comes from [BitTorrent][bittorrent]. In the
BitTorrent protocol, nodes that possess the data for a given torrent file
and begin uploading it to peers are called *seeders*.

In Radicle, while all users contribute to the network by seeding data, the term
*seed node* specifically refers to a server that is accessible through the
internet and hosts content for peers. Seed nodes need to remain online and
accessible to provide their service to the network.

### The need for seed nodes

While a peer-to-peer network without seed nodes is feasible, it is impractical.
This is because regular "user" nodes go online and offline all the time, so
finding a user from which to download a certain piece of content can be
challenging, or even impossible if all users with that content are offline.

Therefore, a healthy peer-to-peer network necessitates at least *some* highly
available nodes that participate in the network like regular peers, but seldom
go offline. These are called seed nodes.

[bittorrent]: https://en.wikipedia.org/wiki/BitTorrent

Getting Started
---------------
For this guide, we'll focus on setting up a seed node using `systemd`. If
you're running a different service manager, you should be able to follow along
just fine, as we'll be explaining the steps. Using a service manager is not
required, but highly recommended.

### What you will need

To run a Radicle seed node, you will need a server with:

* `curl`
* `git`
* `systemctl` version `232` or newer
* `sudo` privileges
* A DNS name pointing to your server

### Server

If you already have a VPS (Virtual Private Server) or home server running a
Linux distribution, you should be all set. If not, any VPS will do. Between 1-2GB
of RAM with a shared CPU and 10GB of disk space should be enough to get started.
Once you've logged into your server, proceed with user setup and installation.
For this setup process, you'll need `sudo` capabilities.

> **Tip**: If you have trouble choosing a VPS, we recommend getting a small
> instance on [Hetzner][hetzner] or [Digital Ocean][do]. These are priced
> fairly and have good documentation and support.

[hetzner]: https://www.hetzner.com/
[do]: https://www.digitalocean.com/

### User setup

If you wish to create a new user under which to run the seed node services,
this is the time. In this guide, we've chosen to run our services under a user
called `seed`. Radicle data and configuration will be stored under this user's
home folder. This ensures that if your Radicle services were to be compromised,
the attacker would have very limited access to your system.

Here's an example user setup with `seed` as the user and group name:

    sudo groupadd --system seed
    sudo useradd --system --gid seed --create-home seed

If you're administering your server via a non-root account, you'll want to
add it to the `seed` group as well:

    sudo usermod -a -G seed $(whoami)

### Installation

For a seed node, you will need to install at minimum the Radicle CLI (`rad`),
and network daemon (`radicle-node`).

To install these, run the following command from within your server's shell:

    curl -sSf https://radicle.xyz/install | sh -s -- --no-modify-path

This will install binaries in `~/.radicle/bin` by default, or in `RAD_PATH`
if you have that set.

Once the binaries are installed, move them to a location accessible by the
`seed` user, for example `/usr/local/bin`.

    sudo mv ~/.radicle/bin/* /usr/local/bin

Finally, login as the `seed` user and proceed with installation:

    sudo su seed

To check your installation, run the `rad` command, and confirm where your
Radicle home is with the `rad path` command.

To offer web browsing and HTTP access to your seed node, you will additionally
need to run `radicle-httpd`, the HTTP daemon. We'll cover this after we've
set up our basic node.

### Creating a profile

Once the Radicle binaries installed, we can create a Radicle *profile*. This
consists of an Ed25519 key pair and directory under which Radicle stores user
data.

    rad auth --alias seed.mentharos.net

The above command will create a profile with the given node *alias* in
`~/.radicle`, or `$RAD_HOME` if set. We recommend setting your alias to the
domain name that points to your node's host.

For seed nodes, it's not generally necessary to set up a passphrase for your
key, so you can simply skip that prompt by pressing *enter*.

<aside>
Seed nodes do not typically sign any permanent artifacts with their key. It
is mainly used for securing connections with peers.
</aside>

> **Tip**: If you wish to set a passphrase anyway, you will have to set the
> `RAD_PASSPHRASE` environment variable in your node's systemd unit file.

Once your profile is initialized, a decentralized identifier (DID) will be
output. The part after the `did:key:` prefix is your Node ID. This is how your
seed node will be identified on the network. The Node ID is the public part of
the Ed25519 key pair generated above, via `rad auth`.

You can view information about your Radicle profile by running `rad self`. The
`--nid` and `--alias` flags can be used to return the Node ID and alias.

Configuring your node
---------------------
There are a couple of things we need to configure to set up a seed node.

First, we must set the node's default *seeding policy*.

The seeding policy tells the node which repositories and forks to fetch
and offer to the network. For public seed nodes, a permissive seeding policy
is often set, such that all data on the network is stored and replicated.

Second, we must set an external address for the node to be reached on the
network. This address will be advertised to peers, allowing them to connect to
your seed node. Generally, this will be a DNS name with port `8776`, for
example `seed.mentharos.net:8776`.

Here's an example configuration file with a permissive seeding policy and
external address set:

```json
{
  "node": {
    "alias": "seed.mentharos.net",
    "externalAddresses": ["seed.mentharos.net:8776"],
    "policy": "allow",
    "scope": "all"
  }
}
```

Your node can be configured with a file named `config.json` in your
Radicle home directory. You can get the full path of the config file with the
`rad self --config` command. Additionally, you can output the current
configuration with `rad config`. Attributes that aren't set in `config.json`
will take on default values. Create a default configuration by running:

    rad config init

Then, edit your configuration using the example above, with the correct
external address under which your node is reachable.

If you are running a firewall, ensure that port `8776` is open for TCP
connections.

> **Tip**: It's recommended to run a basic firewall to further lock down your
> server, using something like `iptables`, though this is out of scope for this
> guide.

### Running your node for the first time

Before setting up your node as a system service, it's a good idea to run it
once to make sure everything is working properly. Enter the following command
to start your node in the foreground:

    rad node start --foreground

You should see log output as your node starts to sync with the network.
If there are any errors or issues connecting to the network, you should see
errors in the output.

If the node started without problem, stop it with `Ctrl-C`, and proceed to the
next step.

### Securing the `seed` user

Now that your node is configured and working, you can secure the `seed` user by
disabling shell access. This is optional, though recommended.

    sudo chsh -s /usr/sbin/nologin seed

This will prevent anyone from logging in as the `seed` user. Exit the `seed`
session by entering:

    exit

This should throw you back into the original session you opened via SSH. Note
that from this point onwards, if you chose to disable the `seed` user's shell,
you'll have to run all commands via `sudo`, eg. `sudo -u seed -- rad self`.

> **Tip**: To facilitate running commands as the `seed` user, add this alias to
> your admin shell's init scripts:
>
>     alias rad='sudo -u seed -- rad'
>
> You can then run commands as the `seed` user by simply using `rad` as usual.

### Configuring your node as a system service

Though it's possible to simply run the Radicle node as a background process,
it's recommended to set up a service to ensure the node is started on boot.

In this guide, we will only cover setup using `systemd`, but the process is
fairly similar for other service managers.

The first thing to do is to get a copy of the [`radicle-node.service`][radicle-node]
unit file. Place it in `/etc/systemd/system/radicle-node.service` for it to
be found by `systemctl`:

    sudo curl -sS https://seed.radicle.xyz/raw/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/570a7eb141b6ba001713c46345d79b6fead1ca15/systemd/radicle-node.service -o /etc/systemd/system/radicle-node.service

Make sure it fits your needs by editing the file directly, or creating an
override using `systemctl edit`.

Then, enable and run the service:

    sudo systemctl enable --now radicle-node

You can check that your node service is running with:

    sudo systemctl status radicle-node

### Sharing your node address

For others to be able to connect to your node directly, they need your *Node
Address*. This is a combination of your Node ID and your node's external
address.

If you've configured one or more external addresses, simply entering the
following command will output your node addresses:

    rad node config --addresses

Share this with others, and they will be able to connect to your node using
`rad node connect <address>`, or by adding your address to their configuration,
under the `node.connect` field.

### Checking your node status

Besides using `systemctl status`, you can also check your node's status using
`rad node status`. This will give you information on the peers connected to
your node. You'll have to run this as the `seed` user, like so:

    sudo -u seed -- rad node status

To tail your node's logs, use:

    sudo journalctl --unit radicle-node --follow

Seeding policies
----------------
With your node running, it's time to configure your seeding policy. The most
important setting is your *default seeding policy*. This setting will determine
what content your seed node fetches and replicates on the network when it
encounters a repository it hasn't given special instructions for.

The setting is configured under the `node.policy` field in your configuration
(`~/.radicle/config.json`). You can open your configuration file directly
using the `rad config edit` command, or use your preferred editor. You can
also enter the following command:

    rad config get node.policy

When a seeding policy is *not set* for a specific repository or node, the
default policy is applied, hence the importance of this setting.

Broadly, there are two options for the default policy.

### A *permissive* seeding policy

A permissive or "open" policy is said to be *fully-replicating*, meaning your
seed will try to have a fully copy of all repository data available on the
network.

An example of a node with this policy is `seed.radicle.garden`, a node operated
by the Radicle team, for the Radicle community.

This is a good default for seeders who want to support the network without
having to think about it too much.

Set `node.policy` to `allow` to configure your node this way.

### A *selective* seeding policy

A selective or *restricted* policy requires you, the operator, to manually
allow repositories to be seeded. This means that the node will ignore
all repositories, except the ones that are pre-configured to allow seeding.

An example is the `seed.radicle.xyz` node, which only seeds core team
repositories.

This is a good policy for communities, teams, companies and individuals who
want to limit the data hosted by their seed, or node operators who want
to require some form of authentication or payment for seeding.

Set `node.policy` to `block` to enable this, and call `rad seed` to configure
`allow` policies for specific repositories you want to seed. Your seed node
won't seed anything until you explicitly allow it to.

### Restart your node

Once you've confiugred your default policy, make sure your configuration is
valid and as intended by calling `rad config`. Then, restart your node for the
changes to take effect:

    sudo systemctl restart radicle-node

### Setting a repository's seeding policy

To override the default policy for a specific repository, the `seed` and
`block` commands are used. For example, if the default policy is `block`, we
can decide to *allow* a repository to be seeded by calling `rad seed`.
For example,

    rad seed rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5

This will override the default `block` rule for this one specific repository.
To remove this override, `unseed` can be used:

    rad unseed rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5

Without a seeding policy for this repository, the default policy will apply.

In the case of an *open* seeding policy, where the default is `allow`, we
can explicitly *block* certain repositories from being seeded. For example,

    rad block rad:z9DV738hJpCa6aQXqvQC4SjaZvsi

This will override the default policy and ensure that this repository is never
replicated on your node.

### Viewing policies

You can view your node's *default* policy with `rad config`, under the
`node.policy` attribute, or by simply entering:

    rad config get node.policy

To view the policy of a specific repository, use the `rad inspect` command. For
example:

    rad inspect rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5 --policy

This will fallback to the default policy if you haven't set any repository
specific policy.

Finally, to view all seeding policies that have been set on repositories,
simply enter `rad seed` with no options. This will list all configured policies.

Configuring the HTTP backend
----------------------------
In the sections above, we set up `radicle-node`, a background process that
actively and continuously discovers and replicates repositories on the network,
based on your seeding policy. This node allows users to collaborate, host,
share and publish repositories on the network via the Radicle CLI or any
compatible application. However, repositories on your seed node cannot be
browsed or viewed without cloning them first, using Radicle. To enable
web browsing of the content, the Radicle HTTP Daemon `radicle-httpd` needs to
be deployed alongside `radicle-node`.

The HTTP Daemon is a background process that functions as a *gateway* between
the Radicle protocol and the HTTP protocol. It is configured to have direct
access to the node's storage and database and expose this data via an
HTTP JSON API. For seed nodes, the HTTP Daemon is always configured as a
*read-only* service over the node's state.

### Configuring your HTTP daemon as a system service

As with `radicle-node`, we can start by downloading an example `systemd` unit
file for the daemon:

    sudo curl -sS https://seed.radicle.xyz/raw/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/570a7eb141b6ba001713c46345d79b6fead1ca15/systemd/radicle-httpd.service -o /etc/systemd/system/radicle-httpd.service

Make sure it fits your needs by editing the file directly, or creating an
override using `systemctl edit`.

Then, enable and run the service:

    sudo systemctl enable --now radicle-httpd

You can check that your node service is running with:

    sudo systemctl status radicle-httpd

You can query the API with `curl` to ensure everything is working properly:

    curl http://127.0.0.1:8080/api/v1

### Adding support for HTTPS

For your HTTP Daemon to be accessible from a frontend such as
<https://app.radicle.xyz>, it needs to respond to HTTPS requests. To do this,
we recommend using [Caddy][caddy].

Start by installing `caddy`; most linux distributions have a package you can
install. If you are using Debian or Ubuntu, you can run:

    sudo apt-get install caddy

If you're having trouble installing Caddy, check the [installation
guide][caddy-install]. Once installed, run `caddy version` to ensure that
everything was installed correctly.

    caddy version
    v2.6.4 h1:2hwYqiRwk1tf3VruhMpLcYTg+11fCdr8S3jhNAdnPy8=

Then, download the `caddy` unit file from Caddy's GitHub repository:

    sudo curl https://raw.githubusercontent.com/caddyserver/dist/master/init/caddy.service -o /etc/systemd/system/caddy.service

Edit the file and change the `User` and `Group` attributes to `seed`, as we
have for the other services. Also ensure that `ExecStart` and `ExecReload`
are set to the correct path. You can find the path under which `caddy` is
installed by running the `which caddy` command.

Finally, edit or create the `Caddyfile` at `/etc/caddy/Caddyfile`, and replace
its contents with the following configuration, using the correct domain name
for your seed:

    seed.mentharos.net {
        reverse_proxy 127.0.0.1:8080
    }

This will proxy all HTTPS requests from port `443` to your HTTP daemon running
on port `8080`. Make sure your firewall has port `443` open for incomning TCP
connections.

Finally, enable and start the Caddy service:

    sudo systemctl enable --now caddy

If you encounter issues setting up Caddy, you can try following their
[guide][caddy-guide] instead.

If everything worked, you should now have HTTPS support for your daemon. To
check, run the following command with your seed's domain:

    curl https://seed.mentharos.net/api/v1

You should now be able to visit your seed node via any Radicle web frontend as
well. For example, <https://app.radicle.xyz/nodes/seed.mentharos.net>.

### You're all set

If you got this far, congratulations, you now have a Radicle seed node up
and running!

🎊👾

[radicle-node]: https://seed.radicle.xyz/raw/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/570a7eb141b6ba001713c46345d79b6fead1ca15/systemd/radicle-node.service
[caddy]: https://caddyserver.com/
[caddy-guide]: https://caddyserver.com/docs/running#linux-service
[caddy-install]: https://caddyserver.com/docs/install
