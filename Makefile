TLD ?= dev
CONFIG = --config _config.yml,_config.$(TLD).yml

default:
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

publish: default
	wrangler deploy --name="website-$(TLD)"

.PHONY: default publish
