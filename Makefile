default: _site
	bundle exec jekyll build

serve:
	bundle exec jekyll serve --port 3000

dependencies:
	gem install jekyll

svgs:
	scripts/cleanup-svgs.sh assets/images/*.svg

publish:
	bundle exec jekyll build
	vercel --prod

.PHONY: publish
