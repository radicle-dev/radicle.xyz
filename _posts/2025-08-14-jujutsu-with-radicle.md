---
title: "Jujutsu + Radicle = ❤️"
subtitle: "How I use Jujutsu in tandem with Radicle"
author: "fintohaps"
authorUrl: "https://app.radicle.xyz/nodes/seed.radicle.garden/users/did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM"
layout: "blog"
---

Roughly a year ago at the first ever [Local First Conference], a friend and
previous colleague – [Alex Good] – told me about this tool called
`jj` ([Jujutsu][jj]). We did the usual thing and I sat down beside him as he
explained it to me. My brain did the usual thing and took in some of the
information but not enough of it, and so I didn't touch `jj` for quite some time
after that – but what's good enough for Alex Good is good enough for me.

After that, I feel like I saw a post about `jj` once every couple of months on
Hacker News – confirmation bias anyone? It was a constant talking point during
Git Merge 2024, and now it's a third Git tool that uses the concept of change
identifiers, so it's a talking point on the [Git mailing list][git-list-change-id-topic].

So, fast-forward a year or so, and I've been using `jj` for quite some time
while contributing to and maintaining the [heartwood repository][heartwood] –
the home of the Radicle protocol – as well as some others. Did I have to
convince my whole team that `jj` should be used by all of us and we all switch
to this new workflow? No. The first piece of "magic" of `jj` is that it is
essentially a version control system that has a transparent layer on top of Git
itself. A change in `jj` will always point to a Git commit. The beauty of its
implementation is that the underlying commit can change as much as it wants,
while the `jj` change remains the same. This unlocks a lot of nice flows for
managing changes using `jj`.

So, you must be wondering by now, "How do I blend Radicle with `jj`?" Well,
let's dance between the three worlds of `jj`, Git, and Radicle, to see how they
have melted together to form a beautiful (_almost_) branch-less workflow.

### Radicle and Git

I won't spend too much time here, but if you don't know by now, Radicle works on
top of Git to allow people to use this ubiquitous tool, while we benefit from
its storage and protocol. When you start a Radicle repository, it's essentially
a Git repository where we use some special references and extension points of
Git to cryptographically secure your commits, and store all your
[social, collaborative artifacts][guide-user-cobs]. If you haven't yet, go
[download] Radicle and try it yourself using our [guides].

Note that if you're already familiar with `jj` this might not be that
interesting for you, and you can skip to [User Config](#user-config).

#### My `.git/config`

As a maintainer of a few repositories using Radicle, I naturally need to push to
and fetch from the repository in Radicle [storage][rip-storage]. This means
that I'll need a remote – this is set up for you when you run `rad init` or `rad
clone`. This looks like:

<pre class="wide">
[remote "rad"]
	url = rad://z371PVmDHdjJucejRoRYJcDEvD5pp
	fetch = +refs/heads/*:refs/remotes/rad/*
	fetch = +refs/tags/*:refs/remotes/rad/tags/*
	pushurl = rad://z371PVmDHdjJucejRoRYJcDEvD5pp/z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM
[branch "master"]
	remote = rad
	merge = refs/heads/master
</pre>

The `rad://` URL tells `git` which [remote helper][git-remote-helpers] to use
by trying to find `git-remote-rad`. This will handle fetching/pushing from/to
the repository identified by `z371PVmDHdjJucejRoRYJcDEvD5pp`. The string
`z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM` is my Node ID, and
identifies my machine
which makes sure that when I push, my references get stored under that
[namespace][rip-storage-namespace]. Then when have the usual upstream branch setup
for `master` for the `rad` remote – you may be familiar with this Git config entry
when you have your `origin` set up for another Git forge.

There's one last piece of the puzzle in config that is an alias for easily
creating a Radicle [patch][guide-user-patch].

```ini
[alias]
    patch = push rad HEAD:refs/patches
```

When you push to the special reference `refs/patches`, the remote helper will
catch this and create a new patch for you, and in this case it will use whatever
`HEAD` is for the head of the patch. Note that it will use whatever `rad/master`
is as the base of the patch – that is to say, whatever commits are between
`rad/master` and `HEAD` (including `HEAD`) are the commits being proposed by the
patch. So, whenever I'm ready to make a patch, I use `git patch` and my
`$EDITOR` pops open to make my well-crafted message describing what changes I'm
making.

#### `git fetch rad` and `git push rad`

This is going to be brief. All I do with `git` now is `git fetch rad` (or my
peer's remotes) to fetch any new work in Radicle storage. For pushing I will use
`git push rad` to create or update patches (coming up), update my version of
`master`, and, on the rare occasion, push a branch. That's it! No more `commit`,
no more `rebase`, no more `merge` – ok I still use `git log` – but that's pretty
much it. So how did I ditch all of these commands? Let's take a look `jj`.

### Jujutsu and Git

Let's see how I'm using `jj` by visiting several of its commands and seeing how
I can use them in different scenarios.

#### `jj new`

It's only natural to start off with `jj new`. This command creates a new change
in `jj`, as well as creating a new, empty commit for that change. Whenever I'm
going to make a new change that's based on the `master` branch, I run:

<pre class="wide">
$ jj new master@rad
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">qx</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">8e</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">711a87</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(no description set)</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">xsl</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">qmmsl</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">62</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">cdaf6d</span> <span style="color:purple;">master@rad</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;"> | </span>deployment: Vercel → Cloudflare Workers
Added 0 files, modified 0 files, removed 1 files
</pre>

You'll notice that `jj` spits out a Change ID and a Commit ID. You may also
notice that a prefix is highlighted – this is the unique prefix for the change
and the commit at this time! Which means that I can use `qx` or `8e` to refer to
this particular change or commit without any ambiguity; an amazing UX, if you
ask me.

At this point, I might know what I'm going to be working on so I use `jj
describe` to give this change a message.

<pre class="wide">
$ jj describe -m <span style="color:green;">"blog: Radicle and JJ"</span>
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">qx</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">40</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">8133a5</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> blog: Radicle and JJ</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">xsl</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">qmmsl</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">62</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">cdaf6d</span> <span style="color:purple;">master@rad</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;"> | </span>deployment: Vercel → Cloudflare Workers
</pre>

I've now changed the description so that it no longer says `(no description
yet)`, and it now reads `blog: Radicle and JJ`.

So let's see what we have here:

<pre class="wide">
$ jj show qx
Commit ID: <span style="color:blue;">408133a5e54c80d2398be0c78cccabbd6063902d</span>
Change ID: <span style="color:purple;">qxuvyurnqsvupzlpzsvzzpqlmlqvoxwq</span>
Author   : <span style="color:olive;">Fintan Halpenny</span> &lt;<span style="color:olive;">fintan.halpenny@radicle.xyz</span>&gt; (<span style="color:teal;">2025-06-10 07:52:34</span>)
Committer: <span style="color:olive;">Fintan Halpenny</span> &lt;<span style="color:olive;">fintan.halpenny@radicle.xyz</span>&gt; (<span style="color:teal;">2025-06-10 07:52:34</span>)

    blog: Radicle and JJ
</pre>

We can see that it looks similar to a Git commit, which we can also inspect
using:

<pre>
$ git show 408133a5e54c80d2398be0c78cccabbd6063902d
<span style="color:olive;">commit 408133a5e54c80d2398be0c78cccabbd6063902d</span>
Author: Fintan Halpenny &lt;fintan.halpenny@radicle.xyz&gt;
Date:   2025-06-10 07:52:34 +0200

    blog: Radicle and JJ
</pre>

This leaves us in a position to do our usual changes within our working copy of
the Git repository.

At any point where I'm looking to separate changes, I can use `jj new` again,
specifying any change to make a new change after the given change:

<pre>
$ jj new qx
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">w</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">msmovxx</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">c5</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">0301c1</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(no description set)</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">qx</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">40</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">8133a5</span> blog: Radicle and JJ
</pre>

<pre class="wide">
$ jj describe -m <span style="color:green;">"blog: Radicle an JJ - add body"</span>
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">w</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">msmovxx</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">a3</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">d195ad</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> blog: Radicle and JJ – add body</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">qx</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">40</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">8133a5</span> blog: Radicle and JJ
</pre>

If I ever think I'm about to make some changes before the change I'm on, then I
can use the `-B` option:

<pre class="wide">
$ jj new -B @
Rebased 1 descendant commits
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">zv</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">rmpyox</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">f0</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">635336</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(no description set)</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">xsl</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">qmmsl</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">62</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">cdaf6d</span> <span style="color:purple;">master@rad</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;"> | </span>deployment: Vercel → Cloudflare Workers
Added 0 files, modified 0 files, removed 1 files
</pre>

#### `jj edit`

At any point in time, I can also decide to go back to an old change and edit it,
specifying the change that I want to edit:

<pre class="wide">
$ jj edit qx
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">qx</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">40</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">8133a5</span><span style="font-weight:bold;"> blog: Radicle and JJ</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">xsl</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">qmmsl</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">62</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">cdaf6d</span> <span style="color:purple;">master@rad</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;"> | </span>deployment: Vercel → Cloudflare Workers
</pre>

You can now forget about all those `fixup!` commits you were making to add
changes into previous commits. No longer are you at the mercy of making a commit
that is ahead of some other changes and you need to reorder it using `git
rebase`. You taste that? It tastes like victory...

#### `jj squash`

Ok, so you've made some changes that are not related to the current change? This
happens, or at least it does to me – I'm not perfect, (un)fortunately. I can use
the power of `jj new`, whether after or before the current change, and combine
it with `jj squash`:

<pre class="wide">
$ jj squash -u --from w --to qx
Rebased 1 descendant commits
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">qx</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">1e</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">2b0ccc</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> blog: Radicle and JJ</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">xsl</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">qmmsl</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">62</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">cdaf6d</span> <span style="color:purple;">master@rad</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;"> | </span>deployment: Vercel → Cloudflare Workers
</pre>

This says that I'm squashing the changes from the change identified by `w` into
the change `qx`, and I want to keep the description of `qx` and drop the
description of `w` (the `-u` option).

For extra points, `jj` even includes the beautiful `-i` option for _choosing_
which changes you're taking from the source change – via a TUI. I cannot
begin to describe how useful this is for moving around file changes and keeping
my history clean and linear.

#### `jj rebase`

The final piece of the puzzle, at least for my workflow, is `jj rebase`. I can
move around changes and put them on top of a destination change:

<pre>
$ jj rebase -d qx -r sm
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">sm</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">vvuqzo</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">42</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">0180e8</span> blog: relevant blog material
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">qx</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">uvyurn</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">1e</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">2b0ccc</span> blog: Radicle and JJ
Added 1 files, modified 0 files, removed 0 files
</pre>

This rebases the change `sm` onto the change `qx`. In fact, the `-r` can take a
set of changes (see [revsets][jj-revsets]) and graft them all on top of the
destination.

#### My `.jj/config`

The final part I'll touch on is my `jj` config, which can be split into the user
and repo config. Thanks to Bruno, who wrote a lot of this on Zulip, and I
cribbed it from him.

##### User Config

Here is my user config, and we'll discuss a couple of the entries, and I'll
leave the rest as homework.

<pre class="wide">
[aliases]
dlog = ["log", "-r"]
l = ["log", "-r", "(trunk()..@):: | (trunk()..@)-"]
fresh = ["new", "trunk()"]
tug = [
    "bookmark",
    "move",
    "--from",
    "closest_bookmark(@)",
    "--to",
    "closest_pushable(@)",
]

[revset-aliases]
"closest_bookmark(to)" = "heads(::to & bookmarks())"
"closest_pushable(to)" = "heads(::to & mutable() & ~description(exact:\"\") & (~empty() | merges()))"
"desc(x)" = "description(x)"
"pending()" = ".. ~ ::tags() ~ ::remote_bookmarks() ~ @ ~ private()"
"private()" = "description(glob:'wip:*') | \
    description(glob:'private:*') | \
    description(glob:'WIP:*') | \
    description(glob:'PRIVATE:*') | \
    conflicts() | \
    (empty() ~ merges()) | \
    description('substring-i:\"DO NOT MAIL\"')"
</pre>

- `fresh`: this allows me to have an alias for `jj new master@rad` and use `jj
  fresh`.
- `tug`: this allows me to tug the closest [bookmark][jj-bookmarks] to a change
  that can be pushed – we'll see an example of this later.

##### Repository Config

And here is my repository config, which we'll discuss a bit more in detail.

```toml
[revset-aliases]
"trunk()" = "master@rad"
"immutable_heads()" = "present(trunk()) | \
    tags() | \
    ( \
        untracked_remote_bookmarks() ~ \
        untracked_remote_bookmarks(remote='rad') ~ \
        untracked_remote_bookmarks(regex:'^patch(es)/',remote='rad') \
    )"

[git]
write-change-id-header = true
```

We want to change the `trunk()` alias from its default in `jj` so that it points
to `master@rad`, the default branch in this particular Radicle repository. The
`trunk()` revset is used in a few place, for example, we saw it above in
`fresh`, but it is also in the next revset alias.

Some changes in `jj` will be marked as [immutable][jj-immutables-heads]. `jj`
will prevent you from changing certain changes if they are marked as immutable,
and its default value for this can be very restrictive, so instead we change it
here. First we mark changes that are `present` in `trunk()` or `tags()` as
immutable. Then we have untracked remote bookmarks with the set difference
operator `~`. What are not marking as immutable are bookmarks that are in `rad`
or that `patch`/`patches`. That is, if the changes are ours or from patches,
then they're safe to edit. You might think, "Why are patches safe?"" Well, let's
finally get into Radicle and Jujutsu.

### Radicle and Jujutsu

So here we are, a lot of build up to get to the point where I can describe how I
can avoid using branches (as much as possible).

#### Contributing Patches

We will first dive into contributing a new patch using Radicle. As described in
[Jujutsu and Git](#jujutsu-and-git), I can start making a set of changes using
`jj new`, editing them just how I like using `jj edit`, and ordering them just
the way I want with `jj rebase` and `jj squash`. During this whole time, I'm in
that, initially scary, [detached HEAD state][detached-head]. Here it comes,
we're going to make a patch!

##### Creating a New Patch

```
git patch
```

That's it. Well, the `$EDITOR` opens and I write a title and a body describing
my wonderful changes, and when I'm done, the remote helper will create the patch
and announce it to the network.

<pre class="wide">
<span style="color:green;">✓</span> Patch <span style="color:teal;">e5f0a5a5adaa33c3b931235967e4930ece9bb617</span> opened
<span style="color:green;">✓</span> Synced with <span style="color:green;">8</span> node(s)

To rad://z3cyotNHuasWowQ2h4yF9c3tFFdvc/z6MkvZwzK64f3GuDcAs6dEcje89ddfHkBjS1v9Dkh7aCGq3C
 * [new reference]   HEAD -&gt; refs/patches
</pre>


##### Updating a Patch

Let's be honest though, my wonderful changes are rarely wonderful from the
get-go. They need some polishing, and my peers always have great suggestions
that I should integrate into the patch.

From here, I can find the patch using `rad patch`:

<pre>
$ rad patch
<span style="color:#2a2a2a;">╭</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">╮</span>
<span style="color:#2a2a2a;">│ </span>●  <span style="font-weight:bold;">ID</span>       <span style="font-weight:bold;">Title</span>                                                  <span style="font-weight:bold;">Author</span>                          <span style="font-weight:bold;">Reviews</span>    <span style="font-weight:bold;">Head</span>     <span style="font-weight:bold;">+</span>      <span style="font-weight:bold;">-</span>      <span style="font-weight:bold;">Updated</span>     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">├</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">┤</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">18a71ad</span>  radicle-cli: Warn when using old names of nodes        <span style="color:purple;">self</span>           <span style="font-style:italic;color:purple;">(you)</span>            - - - - -  <span style="color:blue;">552f4af</span>  <span style="color:green;">+146</span>   <span style="color:red;">-3</span>     <span style="font-style:italic;">4 days ago</span>  <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">ed450c9</span>  node, profile, ssh: Make key location configurable     <span style="color:purple;">self</span>           <span style="font-style:italic;color:purple;">(you)</span>            - - - - -  <span style="color:blue;">d2f7b89</span>  <span style="color:green;">+376</span>   <span style="color:red;">-74</span>    <span style="font-style:italic;">1 month ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">12bc851</span>  node, cli: Refactor test environment                   <span style="color:purple;">self</span>           <span style="font-style:italic;color:purple;">(you)</span>            - - - - -  <span style="color:blue;">d059957</span>  <span style="color:green;">+826</span>   <span style="color:red;">-1214</span>  <span style="font-style:italic;">1 month ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">3219ef8</span>  Remove predefined bootstrap nodes                      <span style="color:purple;">istankovic</span>     <span style="color:purple;">z6MkmiJ…mkTV5sS</span>  - - - - -  <span style="color:blue;">7322e3a</span>  <span style="color:green;">+138</span>   <span style="color:red;">-108</span>   <span style="font-style:italic;">2 days ago</span>  <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">058586b</span>  Suggest the git configured default branch during init  <span style="color:purple;">stemporus</span>      <span style="color:purple;">z6MkqLa…jr8xo5K</span>  - - - - -  <span style="color:blue;">6a1147f</span>  <span style="color:green;">+16</span>    <span style="color:red;">-8</span>     <span style="font-style:italic;">2 weeks ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">1015e51</span>  build: Rewrite tagging script                          <span style="color:purple;">fintohaps</span>      <span style="color:purple;">z6Mkire…SQZ3voM</span>  - - - - -  <span style="color:blue;">149de0b</span>  <span style="color:green;">+24</span>    <span style="color:red;">-12</span>    <span style="font-style:italic;">3 weeks ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">e85ff9a</span>  node: clean up `UploadError`                           <span style="color:purple;">fintohaps</span>      <span style="color:purple;">z6Mkire…SQZ3voM</span>  - - - - -  <span style="color:blue;">b408e44</span>  <span style="color:green;">+15</span>    <span style="color:red;">-13</span>    <span style="font-style:italic;">3 weeks ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">c54883e</span>  Canonical References                                   <span style="color:purple;">fintohaps</span>      <span style="color:purple;">z6Mkire…SQZ3voM</span>  - - - - -  <span style="color:blue;">34014a6</span>  <span style="color:green;">+4642</span>  <span style="color:red;">-1575</span>  <span style="font-style:italic;">1 month ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">e500399</span>  radicle: improve inline comments                       <span style="color:purple;">fintohaps</span>      <span style="color:purple;">z6Mkire…SQZ3voM</span>  - - - - -  <span style="color:blue;">e7cab63</span>  <span style="color:green;">+924</span>   <span style="color:red;">-244</span>   <span style="font-style:italic;">1 month ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">6080c3c</span>  Add issue instructions                                 <span style="color:purple;">yorgos-laptop</span>  <span style="color:purple;">z6MkrnX…CPFSFS3</span>  - - - - -  <span style="color:blue;">1877285</span>  <span style="color:green;">+32</span>    <span style="color:red;">-15</span>    <span style="font-style:italic;">1 month ago</span> <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">40a8d72</span>  radicle: introduce COB stream                          <span style="color:purple;">fintohaps</span>      <span style="color:purple;">z6Mkire…SQZ3voM</span>  - - - - -  <span style="color:blue;">ec00acb</span>  <span style="color:green;">+1178</span>  <span style="color:red;">-9</span>     <span style="font-style:italic;">4 months ago</span><span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span>  <span style="color:teal;">8ab3f9c</span>  Add document on how to implement a new COB type        <span style="color:purple;">liw</span>            <span style="color:purple;">z6MkgEM…1b2w2FV</span>  - - - - -  <span style="color:blue;">5a3b095</span>  <span style="color:green;">+314</span>   <span style="color:red;">-0</span>     <span style="font-style:italic;">1 year ago</span>  <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">╰</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">╯</span>
</pre>

Let's say I received feedback on my `Canonical References` patch, I can use its
`ID`, the shortened version above, to inspect it:

<pre class="wide">
$ rad patch show c54883e
<span style="color:#2a2a2a;">╭</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">╮</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Title</span>     <span style="font-weight:bold;">Canonical References</span>                                                       <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Patch</span>     c54883e5ffb1f8a99f432e3ac79c0b728cd0dab3                                   <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Author</span>    <span style="color:purple;">fintohaps</span> <span style="color:purple;">z6Mkire…SQZ3voM</span>                                                  <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Head</span>      <span style="color:blue;">34014a67b0ddc859d95e17ffc71c1ae61aff5758</span>                                   <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Branches</span>  <span style="color:olive;">patch/c54883e, sync-goal</span>                                                   <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Commits</span>   ahead <span style="color:green;">6</span>, behind <span style="color:red;">49</span>                                                         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">Status</span>    <span style="color:green;">open</span>                                                                       <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>See RIP-0004[^0] for the specification.                                              <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>This patch is an implementation of RIP-0004. It implements the rules mechanism       <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>within the `rules` module. This is interplays with the existing `canonical`          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>mechanisms, already defined (but slightly refactored).                               <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>The `rules` are then used in pushing and fetching references. A test is added to     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>illustrate the canonical references in action via tags.                              <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>There were some incidental changes that were made to ensure the tags use case is     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>easy for users. The first change was to add a tags refspec to remotes in order       <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>to easily fetch tags from peers -- as well ensuring those tags do not pollute        <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>the `refs/tags` namespace in the working copy.                                       <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>This had a knock on change where there was a bug `libgit2` that didn't allow for     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>deleting `multivar` entries, which the new remote setup fell under. This was         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>fixed and so we update to `git2-0.19`.                                               <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>As well this, the `rad id update` command would error if the payload identifier      <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>was not the project identifier. This would stop adding new payloads to extend        <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>the identity -- which was needed for introducing canonical references.               <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>                                                                                     <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>[^0]:                                                                                <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>https://app.radicle.xyz/nodes/seed.radicle.garden/rad:z3trNYnLWS11cJWC6BbxDs5niGo82/ <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>patches/1d1ce874f7c39ecdcd8c318bbae46ffd02fe1ea8?tab=changes                         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">├</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">┤</span>
<span style="color:#2a2a2a;">│ </span><span style="color:blue;">34014a6</span> radicle: refactor rule matching                                              <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:blue;">0e0b77e</span> radicle: add canonical refs to identity                                      <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:blue;">bbe019c</span> radicle: canonical reference rules                                           <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:blue;">b3ad6f2</span> radicle: refactor Canonical                                                  <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:blue;">04277b4</span> radicle: store threshold in Canonical                                        <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:blue;">312c6a4</span> meta: relax radicle-git dependencies                                         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">├</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">┤</span>
<span style="color:#2a2a2a;">│ </span><span style="color:green;">●</span> opened by <span style="color:purple;">fintohaps</span> <span style="color:purple;">z6Mkire…SQZ3voM</span> <span style="color:blue;">(3e97837)</span> 10 months ago                        <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to c1a2cc5787f44c0a835c1deae375be04c399dd7e <span style="color:blue;">(58e932c)</span> 9 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to c55494efc2e780cd6c91a1f90efdae8a3eb1c7ef <span style="color:blue;">(1b07774)</span> 8 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 583e6b3366c36cc7e67910c29a66750397a60484 <span style="color:blue;">(fdd5277)</span> 7 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to d54ddef216909bdd3e54e33e4f82c45df79c00d3 <span style="color:blue;">(f24f9d8)</span> 7 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to ac48ae6e75d4eaa13daed657eed24dfeabb9be94 <span style="color:blue;">(7d8e461)</span> 7 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 2b31e460db7451376dc3e346ee02b5fd597fa5c6 <span style="color:blue;">(040cfb7)</span> 7 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to e1c360a1311a0a215bed6eb42e4b0c8c5c44e611 <span style="color:blue;">(f0dec88)</span> 6 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 492cfbafd31e4bac85ee73af519ddc6254b47f82 <span style="color:blue;">(f9cb27f)</span> 4 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to fbdf18d7683bdac7a76149777eed5cf9bbbf5bd5 <span style="color:blue;">(2a64755)</span> 4 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 4baf32afd65f2c4b374d8f21fed6877aa804a003 <span style="color:blue;">(0cecae6)</span> 4 months ago         <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>  └─ ⋄ reviewed by <span style="color:purple;">self</span> <span style="font-style:italic;color:purple;">(you)</span> 1 month ago                                            <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to d2ebc70caca54a8ba508d72862c1e1c79d718129 <span style="color:blue;">(4515d45)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 13e9ba641c624db26b6bfe85870daf064f90e9ab <span style="color:blue;">(045e465)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 47495c408ccf5eec49b61c7bdb339e5f2d695a30 <span style="color:blue;">(a6be355)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to e3bdb65d3adb94360dd3449744792f6ecb1f451f <span style="color:blue;">(8d08215)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span>  └─ ⋄ reviewed by <span style="color:purple;">erikli</span> <span style="color:purple;">z6MkgFq…FGAnBGz</span> 1 month ago                                <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 9f779028704b4c022cbe25c0e4a9bb46dc8463ba <span style="color:blue;">(49fcea7)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to 86ebfcaaf986edba5e77ede1be4d3c4ce33bd27c <span style="color:blue;">(2df7cd9)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">│ </span><span style="color:teal;">↑</span> updated to fa9bdff35d76903f72cf24f1cccca812ae26e98c <span style="color:blue;">(34014a6)</span> 1 month ago          <span style="color:#2a2a2a;"> │</span>
<span style="color:#2a2a2a;">╰</span><span style="color:#2a2a2a;">───────────────────────────────────────────────────────────────────────────────────────</span><span style="color:#2a2a2a;">╯</span>
</pre>

You can see here how non-perfect my changes are, I'm being vulnerable here.

I can now grab the value `Head` in the above table, and use it in `jj`, by
running `jj new 34014a67b0ddc859d95e17ffc71c1ae61aff5758`. This will drop me
onto a new change after `34014a67b0ddc859d95e17ffc71c1ae61aff5758`, and then I
can use `jj log -r ::@` to see all the previous changes.

Again, I use the wonderful `jj edit` command, or perhaps I make new changes that
I then `jj squash` into the relevant changes – it all depends on the scope of
the change!

Once I'm done, I push `HEAD` to another special [refspec][git-refspec], using
the patch's full identifier:

```sh
git push rad HEAD:patches/c54883e5ffb1f8a99f432e3ac79c0b728cd0dab3 -f
```

We use `-f` if we are editing the changes since this will change the underlying
commits and `git` will reject this. Once again, this will open my `$EDITOR` and
I will add a message about the changes that were made in this update.

This creates a new "revision" for the patch, preserving the older revisions.
So essentially, patches in Radicle are append-only. This makes it safe for us to
make edits to changes, marking them as mutable – the Git history will be
preserved!

#### Maintaining Patches

From the maintaining perspective, the flow starts off similar to updating, where
I would look up the patch that I want to merge. If I made the patch, things are
a bit easier because the Git objects are easily accessible and I can do `jj new`
using the commit. If I attempt to do this with a patch that came from another
contributor, then I may run into this issue:

<pre class="wide">
$ jj new 7322e3ac61669ba6dbde16bb0f7d30edf1ee85ce
<span style="font-weight:bold;"></span><span style="font-weight:bold;color:red;">Error: </span><span style="font-weight:bold;">Revision `7322e3ac61669ba6dbde16bb0f7d30edf1ee85ce` doesn't exist</span>
</pre>

The way to do this instead, is to use the remote syntax and the special
`patches` reference:

<pre>
$ jj new patches/3219ef871dd44c7ef51693f4aeba4c2c5c0c5c7b@rad
Working copy  (@) now at: <span style="font-weight:bold;"></span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:purple;">oo</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">xzsqoy</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:blue;">eb</span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:dimgray;">9e0803</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(empty)</span><span style="font-weight:bold;"> </span><span style="font-weight:bold;filter: contrast(70%) brightness(190%);color:green;">(no description set)</span>
Parent commit (@-)      : <span style="font-weight:bold;"></span><span style="font-weight:bold;color:purple;">s</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">wpyssrk</span> <span style="font-weight:bold;"></span><span style="font-weight:bold;color:blue;">73</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;">22e3ac</span> <span style="color:purple;">patches/3219ef871dd44c7ef51693f4aeba4c2c5c0c5c7b patches/3219ef871dd44c7ef51693f4aeba4c2c5c0c5c7b@rad</span><span style="filter: contrast(70%) brightness(190%);color:dimgray;"> | </span>node, cli: remove predefined bootstrap nodes
</pre>

At this point, I can also look at what commits are in the patch via `rad patch
show`, or by using `jj log -r ::@`. If they're already on top `master@rad`, then
to merge the patch I can simply `git push rad master` – and the remote helper
marks the patch as merged if the canonical reference of `master` is update (a
topic for another time).

If the patch isn't on top of `master@rad` then I can rebase the changes using
`jj rebase -d master@rad -r <base>::<head>` to get the series of changes on top
of our latest. It's then necessary to push a new revision to the patch so that
the patch can know it is being merged with the new commits – remember that I
rebased, so this changes the underlying commits.

We should update our `master` bookmark, and this is where the `tug` alias comes
in. When I run `jj tug`, it figures out that `master` is the closest bookmark
and pulls it up to the latest change that can be pushed. I can then push to
update the patch:

```sh
git push rad master:patches/3219ef871dd44c7ef51693f4aeba4c2c5c0c5c7b -f
```

Here I'm using `master` instead of `HEAD` – this gets around a little issue I've
been seeing for patches that I do not own, where the remote helper rejects the
push because it cannot resolve `HEAD` (a mystery left for another day).

Once the patch has been rebased, I can do the usual `git push rad master` to
update the canonical reference and have the patch marked as merged.

## Conclusion

And our adventure ends here. We dived into how Radicle works with Git, how
Jujutsu works Git, and how I use Jujutsu to have a branch-less flow in Radicle.
This is has been a dream to work with. This type of tooling feels like it
enables me a lot more when managing my changes and keeping a clean history. I
was *able* to do this with `git rebase`, but it felt like it got in the way more
than it enabled me – and I haven't even touched on how [conflicts][jj-conflicts]
are easy in Jujutsu!

There is plenty of room for improvements here, some things on my list are:
- Keeping track of Jujutsu change IDs in Radicle data, which is already being
  looked at!
- Not needing to use `rad patch show` to get metadata for managing patches, and
  perhaps even bookmarking patch identifiers automatically.

Come help in discussion on our [Zulip], and enjoy being Radicle 🌱👾

<!-- Other people and events. --->
[Alex Good]: https://patternist.xyz
[Local First Conference]: https://www.localfirstconf.com/
[detached-head]: https://wizardzines.com/comics/detached-head-state/

<!-- Jujutsu -->
[jj]: https://jj-vcs.github.io/jj/v0.30.0/
[jj-bookmarks]: https://jj-vcs.github.io/jj/v0.30.0/bookmarks
[jj-conflicts]: https://jj-vcs.github.io/jj/v0.30.0/conflicts
[jj-immutables-heads]: https://jj-vcs.github.io/jj/v0.30.0/config/#set-of-immutable-commits
[jj-revsets]: https://jj-vcs.github.io/jj/v0.30.0/revsets

<!-- Git -->
[git-list-change-id-topic]: https://lore.kernel.org/git/CAESOdVAspxUJKGAA58i0tvks4ZOfoGf1Aa5gPr0FXzdcywqUUw@mail.gmail.com/
[git-refspec]: https://git-scm.com/book/en/v2/Git-Internals-The-Refspec
[git-remote-helpers]: https://git-scm.com/docs/gitremote-helpers

<!-- Radicle -->
[heartwood]: https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5
[Zulip]: https://radicle.zulipchat.com
[download]: https://radicle.xyz/download
[guide-user-cobs]: https://radicle.xyz/guides/user#2-collaborating-the-radicle-way
[guide-user-patch]: https://radicle.xyz/guides/user#working-with-patches
[guides]: https://radicle.xyz/guides
[rip-storage]: https://app.radicle.xyz/nodes/ash.radicle.garden/rad:z3trNYnLWS11cJWC6BbxDs5niGo82/tree/0003-storage-layout.md
[rip-storage-namespace]: https://app.radicle.xyz/nodes/ash.radicle.garden/rad:z3trNYnLWS11cJWC6BbxDs5niGo82/tree/0003-storage-layout.md#layout
