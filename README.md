# radicle.xyz

> Visit <https://radicle.xyz>

This is the Radicle homepage and documentation repository.

## Running the website locally

1. Make sure you have [Ruby][ruby] installed
2. Install project dependencies

        make dependencies

3. Build and serve the project

        make serve

4. Visit <http://localhost:3000/> in your web browser

[ruby]: https://www.ruby-lang.org/en/documentation/installation/


## RIPs

They live in `_rips` as a squashed subtree, using `git subtree`.

If you plan to work on the integration with RIPs, it is *very*
helpful to add the repository as a remote:

	git remote add rips rad://z3trNYnLWS11cJWC6BbxDs5niGo82

Then, to update the subtree:

	git subtree --prefix _rips pull rips master

## License

Licensed under [CC BY-NC-SA 4.0][license]. See [LICENSE](LICENSE).

## Copyright

Copyright (C) The Radicle Team

[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/
