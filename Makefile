TLD ?= dev
CONFIG = --config _config.yml,_config.$(TLD).yml

default: _pages/code-of-conduct.patch
	bundle exec jekyll build $(CONFIG)

serve:
	bundle exec jekyll serve $(CONFIG) --port 3000 --livereload

dependencies:
	gem install jekyll

cloudflare:
	sudo gem install bundler
	bundle config path vendor/bundle
	bundle install
	bundle exec jekyll build $(CONFIG)

svgs:
	scripts/cleanup-svgs.sh assets/images/*.svg

code_of_conduct.md:
	curl -o $@ 'https://www.contributor-covenant.org/version/3/0/code_of_conduct/code_of_conduct.md'

_pages/code-of-conduct.patch: code_of_conduct.md _includes/code-of-conduct.md
	printf -- "---\nlayout: none\npermalink: /coc.patch\n---\n" > $@
	-diff -U1024 --label "contributor-covenant.org/code_of_conduct.md" --label "radicle.$(TLD)/code-of-conduct.md" $^ >> $@

publish: default
	wrangler deploy --name="website-$(TLD)"

.PHONY: default publish _includes/code-of-conduct.md
