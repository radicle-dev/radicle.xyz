---
title: "Using Radicle CI for Development"
subtitle: "In this blog post I show how I use Radicle and its CI support for my own software development."
author: lars
layout: blog
---

In this blog post I show how I use Radicle and its CI support for my
own software development. I show how I start a project, add it to
Radicle, add CI support for it, and manage patches and issues.

I have been working full time on Radicle CI for a couple of years now.
All my personal Git repositories are hosted on Radicle. Radicle CI is
the only CI I now use.

There are instructions to install the software I mention here at the
end.

These days, I'm not a typical software developer. I usually work in
Emacs and the command line instead of an IDE. In this blog post I'll
concentrate on the parts of my development process that relate to
Radicle, and not my other tooling.

# Overview of Radicle CI

The Radicle node process opens a Unix domain socket to which it sends
events describing changes in the node. One of these events represents
changes to a repository in the node's storage.

<img src="/assets/images/blog/components.svg" class="screenshot" style="background-color: #f5f5ff;"/>

Support for CI in Radicle is built around the repository change event.
The Radicle CI broker (`cib`), listens for the events and matches them
against its configuration to decide when to run CI. The node operator
gets to decide for what repositories they run CI.

The CI broker does not itself run CI. It invokes a separate program,
the "adapter", which is given the event that triggered CI. The adapter either
executes the run itself, or uses an external CI system to execute it.
This allows Radicle to support a variety of CI systems, by writing a
simple adapter for each.

I have written a CI engine for myself,
[Ambient](https://ambient.liw.fi/), and the adapter for that
(`radicle-ci-ambient`), and that is what I use.

There are adapters for running CI locally on the host or in a
container, GitHub actions, Woodpecker, and several others. See [`CI
broker
README.md`]({{ "radicle.liw.fi rad:zwTxygwuz5LDGBq255RA2CbNGrz8/tree/README.md" | explore }})
and [integration
documentation](https://explorer.radicle.gr/nodes/seed.radicle.gr/rad:z4Uh671FzoooaHjLvmtW9BtGMF9qm)
for a more complete list. The adapter interface is intentionally easy
to implement: it needs to read one line of JSON and write up to two
lines of JSON.

# The sample project

This blog post is about Radicle, so I'm going to use a "hello world"
program as an example. This avoids getting mired into the details of
implementing something useful.

First I create a Git repository with a Rust project. I choose Rust,
because I like Rust, but the programming language is irrelevant here.

```
$ cargo init liw-hello
    Creating binary (application) package
... some text removed
$ cd liw-hello
$ git add .
$ git commit -m "chore: cargo init"
[main (root-commit) 5037847] chore: cargo init
 3 files changed, 10 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 Cargo.toml
 create mode 100644 src/main.rs
```

Then I edit the `src/main.rs` file to have some useful content,
including unit tests:

```
fn main() {
    let greeting = Greeting::default()
        .greeting("hello")
        .whom("world");
    println!("{}", greeting.greet());
}

struct Greeting {
    greeting: String,
    whom: String,
}

impl Default for Greeting {
    fn default() -> Self {
        Self {
            greeting: "howdy".into(),
            whom: "partner".into(),
        }
    }
}

impl Greeting {
    fn greeting(mut self, s: &str) -> Self {
        self.greeting = s.into();
        self
    }

    fn whom(mut self, s: &str) -> Self {
        self.whom = s.into();
        self
    }

    fn greet(&self) -> String {
        format!("{} {}", self.greeting, self.whom)
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn default() {
        let g = Greeting::default();
        assert!(!g.greeting.is_empty());
        assert!(!g.whom.is_empty());
    }

    #[test]
    fn sets_greeting() {
        let g = Greeting::default().greeting("hi");
        assert_eq!(g.greet(), "hi partner");
    }

    #[test]
    fn sets_whom() {
        let g = Greeting::default().whom("there");
        assert_eq!(g.greet(), "howdy there");
    }
}
```

To commit that, I actually use Emacs with Magit for this, but I also often use
the command line, which I show here.

```
git commit -am "feat: implement greeting"
```

Once I have a Git repository with at least one commit, I can create a
Radicle repository for that. I do that on the command line. The `rad
init` command asks the user some questions. The answers could be
provided via option, which is useful for testing, but not something I
usually do when using the program.

```
$ rad init

Initializing radicle 👾 repository in /home/liw/radicle/liw-hello..

✓ Name liw-hello
✓ Description Sample program for blog post about Radicle and its CI
✓ Default branch main
✓ Visibility public
✓ Repository liw-hello created.

Your Repository ID (RID) is rad:z3dhWQMH8J6nX3Qo97o5oSFMTfgyr.
You can show it any time by running `rad .` from this directory.

◤ Uploaded to z6MksCgjxU4VZt6qgtZntdikhtXFbsfvKRLPzpKtfCY4rAHR, 0 peer(s) remaining..
✓ Repository successfully synced to z6MksCgjxU4VZt6qgtZntdikhtXFbsfvKRLPzpKtfCY4rAHR
✓ Repository successfully synced to 1 node(s).

Your repository has been synced to the network and is now discoverable by peers.
Unfortunately, you were unable to replicate your repository to your preferred seeds.
To push changes, run `git push`.
```

There you go. I now have a Radicle repository to play with. As of
publishing this blog post, the repository is alive on the Radicle
network, if you want to [look at
it]({{ "radicle.liw.fi rad:z3dhWQMH8J6nX3Qo97o5oSFMTfgyr" | explore }})
or clone it.

# CI configuration in the repository

To use Radicle CI with Ambient, I need to create
`.radicle/ambient.yaml`:

```
plan:
  - action: cargo_clippy
  - action: cargo_test
```

This tells Ambient to run `cargo clippy` and `cargo test`, albeit with
additional command line arguments.

This is specific to Ambient, and the Ambient adapter for Radicle CI,
but similar files are needed for every CI system. The Radicle CI
broker does not try hide this variance: it's important that you, as
the developer using a specific CI system, get full access to it, even
when you use it through Radicle CI. If the CI broker added a layer
above that it would only cause confusion and irritation.

# Running CI locally

I find the most frustrating part of using CI to be to wait for a CI
run to finish on a server and then try to deduce from the run log what
went wrong. I've alleviated this by writing an extension to `rad` to
run CI locally:
[`rad-ci`]({{ "radicle.liw.fi rad:z6QuhJTtgFCZGyQZhRMZmZKJ3SVG" | explore }}).
It can produce a huge amount of output, so I've abbreviated that
below.

`rad` supports extensions like `git` does: if you run `rad foo` and
`foo` isn't built into `rad`, then `rad` will try to run `rad-foo`
instead. `rad-ci` can thus be invoked as `rad ci`, which I use in the
example below.

```
$ rad ci
...
    RUN: Action CargoClippy
    SPAWN: argv=["cargo", "clippy", "--offline", "--locked", "--workspace", "--all-targets", "--no-deps", "--", "--deny", "warnings"]
           cwd=/workspace/src (exists? true)
           extra_env=[("CARGO_TARGET_DIR", "/workspace/cache"), ("CARGO_HOME", "/workspace/deps"), ("PATH", "/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")]
        Checking liw-hello v0.1.0 (/workspace/src)
        Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.15s
    RUN: Action finished OK
    RUN: Action CargoTest
    SPAWN: argv=["cargo", "test", "--offline", "--locked", "--workspace"]
           cwd=/workspace/src (exists? true)
           extra_env=[("CARGO_TARGET_DIR", "/workspace/cache"), ("CARGO_HOME", "/workspace/deps"), ("PATH", "/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")]
       Compiling liw-hello v0.1.0 (/workspace/src)
        Finished `test` profile [unoptimized + debuginfo] target(s) in 0.18s
         Running unittests src/main.rs (/workspace/cache/debug/deps/liw_hello-9c44d33bbe6cdc80)

    running 3 tests
    test test::default ... ok
    test test::sets_greeting ... ok
    test test::sets_whom ... ok

    test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

    RUN: Action finished OK
    RUN: Action TarCreate {
        archive: "/dev/vde",
        directory: "/workspace/cache",
    }
    RUN: Action finished OK
    RUN: Action TarCreate {
        archive: "/dev/vdd",
        directory: "/workspace/artifacts",
    }
    RUN: Action finished OK
    ambient-execute-plan ends
    EXIT CODE: 0
    [2025-07-04T05:48:23Z INFO  ambient] ambient ends successfully

Everything went fine.
```

(I've used the voluminous output to help debug `rad-ci`, but now that
it is stable, I should reduce the volume by default. A cobbler's
children may have no shoes but a programmer's tool has unnecessary
debug output.)

I find this ability to emulate what happens in CI on a server to be
very useful. To start with, I can use the resources I have locally, on
my laptop. I don't need to compete with the shared server with other
people. I don't have to wait for the CI server to have time for me. I
also don't need to commit changes, which is another little source of
friction removed from the edit-ci-debug cycle.

For Ambient I intend to add support when it's run locally (as `rad-ci`
does), and there's a failure, the developer can log into the
environment and have hands-on access. This will make debugging a
failure under CI much easier than pushing changes to add more output
to the run log to help figure out what the problem is. But that isn't
implemented yet: I only have 86400 seconds per day, most days.

# CI configuration on my CI node

I love being able to run CI locally, but it is not sufficient. One
important aspect of a shared CI is that everyone uses the same
environment, with the same versions of everything. A server can also
deliver or deploy changes, as needed.

I've configured a second node, [ci0](https://ci0.liw.fi/), where I run
the CI broker and Ambient for all the public projects I have or
participate in. The actual server is a small desktop PC I have, which
is quiet and uses fairly little power, especially when idle. The HTML
report pages get published on a public server, for the amusement of
others.

My CI broker configuration is such that I don't need to change it for
every new project. I only need to make sure the repository is on the
CI node, and the repository has a `.radicle/ambient.yaml` file.

To seed, I run this on the CI node:

```
rad seed rad:z3dhWQMH8J6nX3Qo97o5oSFMTfgyr
```

That's the repository ID for my sample project. I run `rad .` in the
working directory to find out what it is. Because finding out the ID
is so easy, I never bother to make note of it when creating a repository.

# Reporting an issue

The `rad` tool can open issues from the command line, but for issue
management I've moved to using [the desktop application](/desktop).
In the screenshot below I open an issue about the default greeting.

<img src="/assets/images/blog/radicle-desktop-new-issue-scaled.png" class="screenshot"/>

In the above picture I show how I open a new issue for the sample
repository, saying the greeting is not the usual "hello world"
greeting.

# Making a change

To make a change to the project, I make a branch, commit some changes,
then create a Radicle patch.

```
$ git switch -c change
Switched to a new branch 'change'
$ git commit -am "feat: change greeting"
[change d19c898] feat: change greeting
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git push rad HEAD:refs/patches
✓ Patch fd552417cc9a66c6aac1b6c8c717996bea741bfd opened
✓ Synced with 11 seed(s)

 * [new reference]   HEAD -> refs/patches
```

The last command above pushes the branch to Radicle, via the special
`rad` remote, and instructs the `rad` Git remote helper to create a
Radicle patch instead of a branch. The `refs/patches` name is special
and magic. The `git-remote-rad` helper program understands it as a
request to create a new patch.

This makes a change in the local node, which by default then
automatically syncs it with other nodes it's connected to, if they
have the same repository. My laptop node is connected to the CI node,
so that happens immediately.

As soon as the new patch lands in the CI node, the CI broker triggers
a new CI run, which fails. I can go to the [web page updated by the CI
broker](https://ci0.liw.fi/z3dhWQMH8J6nX3Qo97o5oSFMTfgyr.html) and see
what the problem is. The patch diff is:


```
diff --git a/src/main.rs b/src/main.rs
index a79818f..216bab7 100644
--- a/src/main.rs
+++ b/src/main.rs
@@ -11,8 +11,8 @@ struct Greeting {
 impl Default for Greeting {
     fn default() -> Self {
         Self {
-            greeting: "howdy".into(),
-            whom: "partner".into(),
+            greeting: "hello".into(),
+            whom: "world".into(),
         }
     }
 }
```

The problem is that tests assume the original default:

```
---- test::sets_greeting stdout ----

thread 'test::sets_greeting' panicked at src/main.rs:50:9:
assertion `left == right` failed
  left: "hi world"
 right: "hi partner"
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace

---- test::sets_whom stdout ----

thread 'test::sets_whom' panicked at src/main.rs:56:9:
assertion `left == right` failed
  left: "hello there"
 right: "howdy there"


failures:
    test::sets_greeting
    test::sets_whom

test result: FAILED. 1 passed; 2 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

I change the tests, run the tests locally, run `rad ci` locally, and
commit the fix..

I then push the fix to the patch. The push default for this branch was
set to the Radicle patch, which makes pushing easier.

```
$ git push
✓ Patch fd55241 updated to revision 8d1f8c69dc0f8028d8b1bb9e336240febaf2d1f4
To compare against your previous revision 3180ddd, run:

   git range-diff c3f02b43830578c93edd83a23ee2902899fdb159 17cda244d2e78bdeffd0647b20f315726bebf605 2a82eb0326179b60664ffeeac3ee062a5adfdcd6

✓ Synced with 13 seed(s)

  https://app.radicle.xyz/nodes/ci0/rad:z3dhWQMH8J6nX3Qo97o5oSFMTfgyr/patches/fd552417cc9a66c6aac1b6c8c717996bea741bfd

To rad://z3dhWQMH8J6nX3Qo97o5oSFMTfgyr/z6MkgEMYod7Hxfy9qCvDv5hYHkZ4ciWmLFgfvm3Wn1b2w2FV
   17cda24..2a82eb0  change -> patches/fd552417cc9a66c6aac1b6c8c717996bea741bfd
```

I wait for CI to run. It is a SUCCESS!

I still need to merge the fix to the `main` branch. This will also
automatically mark the branch as merged for Radicle.

```
$ rad patch
╭───────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ●  ID       Title                                    Author         Reviews  Head     +    -   Updat… │
├───────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ●  fd55241  ci: add configuration Radicle + Ambient  liw     (you)  -        2a82eb0  +14  -4  1 min… │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────╯
$ git switch main
Switched to branch 'main'
$ git merge change
Updating 54d2c9c..2a82eb0
Fast-forward
 Cargo.lock  | 7 +++++++
 src/main.rs | 8 ++++----
 2 files changed, 11 insertions(+), 4 deletions(-)
 create mode 100644 Cargo.lock
$ git push
✓ Patch fd552417cc9a66c6aac1b6c8c717996bea741bfd merged
✓ Canonical head updated to 2a82eb0326179b60664ffeeac3ee062a5adfdcd6
✓ Synced with 13 seed(s)

  https://app.radicle.xyz/nodes/ci0/rad:z3dhWQMH8J6nX3Qo97o5oSFMTfgyr/tree/2a82eb0326179b60664ffeeac3ee062a5adfdcd6

To rad://z3dhWQMH8J6nX3Qo97o5oSFMTfgyr/z6MkgEMYod7Hxfy9qCvDv5hYHkZ4ciWmLFgfvm3Wn1b2w2FV
   c3f02b4..2a82eb0  main -> main
$ rad patch
Nothing to show.
$ delete-merged
Deleted branch change (was 2a82eb0).
```

(The last command is a little helper script that deletes any local
branches that have been merged into the default branch. I don't like
to have a lot of merged branches around to confuse me.)

I could have avoided this round trip via the server by running `rad
ci`, or at least `cargo test`, before creating the patch, but I was
confident that I can't make a mistake in an example this simple. This
is why CI is needed: to keep in control the hubris of someone who has
been programming for decades.

# Installing

To install Radicle itself, the [official instructions](/#get-started)
will get you `rad` and `radicle-node`. The [Radicle desktop application](/desktop)
has its own installation instructions.

There are instructions for installing [Radicle CI (for
Debian)](https://radicle-ci.liw.fi/radicle-ci-broker/userguide.html#installing-radicle-ci-with-ambient-on-debian),
but not other systems, since I only use Debian. I would very much
appreciate help with expanding that documentation.

It's probably easiest to install
[`rad-ci`]({{ "radicle.liw.fi rad:z6QuhJTtgFCZGyQZhRMZmZKJ3SVG" | explore }})
from source code or with `cargo install`, but I have a `deb` package
for those using Debian or derivatives in my [APT
repository](http://apt.liw.fi/).

# Conclusion

I've used CI systems since 2010, starting with Jenkins, just after it
got renamed from Hudson. I've written about four CI engines myself,
depending on how you count rewrites. With Radicle and Ambient I am
finally getting to a development experience where CI is not actively
irritating, even if is not yet fun.

A CI system that's a joy to use, that sounds like a fantasy. What
would it even be like? What would make using a CI system joyful to
you?
