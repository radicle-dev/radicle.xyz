default:
	bundle exec jekyll build

serve:
	bundle exec jekyll serve --port 3000 --livereload

dependencies:
	gem install jekyll

cloudflare:
	sudo gem install bundler
	bundle config path vendor/bundle
	bundle install
	bundle exec jekyll build

svgs:
	scripts/cleanup-svgs.sh assets/images/*.svg

publish: default
	wrangler deploy

.PHONY: default publish
