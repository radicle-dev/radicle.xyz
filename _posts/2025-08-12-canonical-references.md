---
title: "Canonical References"
author: "fintohaps"
layout: post
authorUrl: "https://app.radicle.xyz/nodes/iris.radicle.xyz/users/did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM"
layout: "blog"
---

## Canonical what?

Most people who use Git are used to referring to things called branches
(`refs/heads`). "I pushed the branch", "check out the feature branch to see the
work", "Ok, I'll pull your branch", etc. A branch is simply a specific
kind of reference in a Git. You're also likely familiar with tags
(`refs/tags`), and these are another kind of references, too! A reference,
quite simply, is a name that points to a Git object, like a commit object or a
tag object. The naming convention and what objects they point to allow us to
talk more specifically about branches, remote branches, tags, and notes.

So what's a canonical reference? In the Radicle protocol, all your references
live under your namespace (`refs/namespaces/<nid>/refs/{head,tags,*}`). We want
Radicle repositories to also act like more traditional Git repositories that
have the typical references `refs/heads/main`, `refs/tags/v1.0.0`,
`refs/heads/qa/feature-1`. So we introduced a way to synthesise these references
from the references under the set of `refs/namespaces/<nid>/refs`. These
references become canon[^4] and can be considered for use, e.g. fetching a
specific tag object for building binaries.

## Git History in the Making

Since the dawn of the `heartwood` implementation of the Radicle protocol, the
concept of the `defaultBranch` was included in the identity document. Alongside
this, we have had the `threshold` value. Even more importantly, we have had the
`delegates` managing the identity of the identity document, as well. By
combining these 3 values we were able to calculate the canonical reference of
the `defaultBranch`. The `defaultBranch` becomes a canonical reference when a
`threshold` number of `delegates` decide on a commit to use for its canonical
form.

If you have been using Radicle, you'll have noticed that whenever you push Git
tags that they get placed under your namespace. Most people who have used `git`
would expect these tags to be placed under `refs/tags`. Up until now, we have
broken this expectation, because we are working in a decentralised environment
using Radicle, protecting the global namespace of the repository. So, we asked
ourselves, "Can the `defaultBranch` approach be generalised?" This way, the
`refs/tags` namespace can be populated using the canonical form of the tag.

"It should be easy!", I said – famous last words.

What ensued was a RIP[^0] and two patches[^1][^2], over a time period that felt
like forever. It turned out that evolving things in a protocol can be quite
tricky when it comes to compatibility. You may notice that the merged patch and
the RIP will differ slightly in the approach recommended. For now, the approach
we are using bases itself on the extensible payloads in the identity document.

After all that, we are proud to announce that **you** can now start using
canonical references, so let's go through how to use them.

## A Quick Guide to Canonical References

As alluded to above, we need three values to specify a rule for a canonical
reference. We need a reference the rule applies to, a set of allowed DIDs
(currently always `did:key`s), and a `threshold`. These three values form a
canonical reference rule. In fact, we can generalise the reference value to use
a Git reference pattern[^3].

So, where do these new rules go? The new update of Radicle will now interpret a
new payload identified by the key `xyz.radicle.crefs`. Under this key, it
expects a `rules` key, which in turn can hold a number of canonical reference
rules that are identified by their Git reference pattern.

For each rule, there are two keys: `allow` and `threshold` – these refer to the
allowed set of DIDs and the `threshold` value respectively.

To demonstrate, the maintainers of the `heartwood` repository have prepared a
rule already so that we can use release tags. I (@fintohaps) used the command
`rad id update --edit` to open up my editor with the identity document
pre-populated. I added the new payload with a rule for `refs/tags/releases/*`,
the allowed set of the current 3 maintainers of the repository, and a
`threshold` of 2. Here is what the document looked like when saving:

```json
{
  "payload": {
    "xyz.radicle.project": {
      "defaultBranch": "master",
      "description": "Radicle Heartwood Protocol & Stack",
      "name": "heartwood"
    },
    "xyz.radicle.crefs": {
      "rules": {
        "refs/tags/releases/*": {
          "allow": [
            "did:key:z6MkkPvBfjP4bQmco5Dm7UGsX2ruDBieEHi8n9DVJWX5sTEz",
            "did:key:z6MkgFq6z5fkF2hioLLSNu1zP2qEL1aHXHZzGH1FLFGAnBGz",
            "did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM"
          ],
          "threshold": 2
        }
      }
    }
  },
  "delegates": [
    "did:key:z6MksFqXN3Yhqk8pTJdUGLwATkRfQvwZXPqR2qMEhbS9wzpT",
    "did:key:z6MktaNvN1KVFMkSRAiN4qK5yvX1zuEEaseeX5sffhzPZRZW",
    "did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM",
    "did:key:z6MkgFq6z5fkF2hioLLSNu1zP2qEL1aHXHZzGH1FLFGAnBGz",
    "did:key:z6MkkPvBfjP4bQmco5Dm7UGsX2ruDBieEHi8n9DVJWX5sTEz"
  ],
  "threshold": 1
}
```

And here's the output of the `rad id` command:

```
╭───────────────────────────────────────────────────────────────────────────────────╮
│ Title    Add Release Tag Canonical Refs Rule                                      │
│ Revision 45e43cc54284f579deb7ae64e4d162274c04fa3b                                 │
│ Blob     def6df9a842e68525b371462200b6d5454269601                                 │
│ Author   did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM                 │
│ State    active                                                                   │
│ Quorum   no                                                                       │
│                                                                                   │
│ Adding the `xyz.radicle.crefs` payload that starts with a single for the          │
│ `refs/tags/releases/*` rules that uses Erik, Fintan, and Lorenz as the allowed    │
│ delegates, and a threshold of 2.                                                  │
├───────────────────────────────────────────────────────────────────────────────────┤
│ ✓ did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM fintohaps        (you) │
│ ? did:key:z6MksFqXN3Yhqk8pTJdUGLwATkRfQvwZXPqR2qMEhbS9wzpT cloudhead              │
│ ? did:key:z6MktaNvN1KVFMkSRAiN4qK5yvX1zuEEaseeX5sffhzPZRZW cloudhead-laptop       │
│ ? did:key:z6MkgFq6z5fkF2hioLLSNu1zP2qEL1aHXHZzGH1FLFGAnBGz erikli                 │
│ ✓ did:key:z6MkkPvBfjP4bQmco5Dm7UGsX2ruDBieEHi8n9DVJWX5sTEz lorenz                 │
╰───────────────────────────────────────────────────────────────────────────────────╯

@@ -1,17 +1,29 @@
 {
   "payload": {
+    "xyz.radicle.crefs": {
+      "rules": {
+        "refs/tags/releases/*": {
+          "allow": [
+            "did:key:z6MkkPvBfjP4bQmco5Dm7UGsX2ruDBieEHi8n9DVJWX5sTEz",
+            "did:key:z6MkgFq6z5fkF2hioLLSNu1zP2qEL1aHXHZzGH1FLFGAnBGz",
+            "did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM"
+          ],
+          "threshold": 2
+        }
+      }
+    },
     "xyz.radicle.project": {
       "defaultBranch": "master",
       "description": "Radicle Heartwood Protocol & Stack",
       "name": "heartwood"
     }
   },
   "delegates": [
     "did:key:z6MksFqXN3Yhqk8pTJdUGLwATkRfQvwZXPqR2qMEhbS9wzpT",
     "did:key:z6MktaNvN1KVFMkSRAiN4qK5yvX1zuEEaseeX5sffhzPZRZW",
     "did:key:z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM",
     "did:key:z6MkgFq6z5fkF2hioLLSNu1zP2qEL1aHXHZzGH1FLFGAnBGz",
     "did:key:z6MkkPvBfjP4bQmco5Dm7UGsX2ruDBieEHi8n9DVJWX5sTEz"
   ],
   "threshold": 1
 }
```

You can look at the evolution of the proposal by using `rad id show
45e43cc54284f579deb7ae64e4d162274c04fa3b` in the `heartwood` repository.

Note that since the rules are being added to the identity document, it is
necessary to reach a majority quorum for proposing these changes.

Once the rules are in place, any time you push or fetch a reference that matches
a rule, it will compute the canonical form for that reference. In the case
above, if any of the 2 allowed `did:key`s agree on a tag that lives under their
namespace as `refs/tags/releases`, then a corresponding `refs/tags` will be
computed.

This means that there will be more top-level references appearing in Radicle
repositories, and importantly, tooling and processes that require Git tags can
now take advantage of Radicle repositories!

Now, it's time to go try out this feature and report back to us! Release tags to
your hearts content ❤️🌱

[^0]: RIP-4 Canonical References https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3trNYnLWS11cJWC6BbxDs5niGo82/patches/1d1ce874f7c39ecdcd8c318bbae46ffd02fe1ea8?tab=changes

[^1]: First patch attempting to implement canonical references https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/patches/c54883e5ffb1f8a99f432e3ac79c0b728cd0dab3

[^2]: Second patch implementing canonical references using the identity payload https://app.radicle.xyz/nodes/seed.radicle.xyz/rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5/patches/bea09df15505cfcebc72ad40f629747d2e82f670

[^3]: Git ref format and reference patterns https://git-scm.com/docs/git-check-ref-format

[^4]: Here we are using the term in the sense that some content made may not be considered part of the canon of some story or universe. For example, some Star Wars content may be considered as canon by George Lucas, but some may not be.
