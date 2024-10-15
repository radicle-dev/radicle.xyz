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

# These require somewhat unusual tools to build and we store the
# generated SVGs in Git to avoid having to rebuild them on all
# systems.
arch-svgs:
	scripts/build-pik.sh assets/images/*.pik
	scripts/build-plantuml.sh assets/images/*.uml

publish: default
	wrangler deploy

.PHONY: default publish
