default: _site
	jekyll build

serve:
	jekyll serve --port 3000

dependencies:
	gem install jekyll

svgs:
	scripts/cleanup-svgs.sh assets/images/*.svg

publish:
	jekyll build
	vercel --prod

.PHONY: publish
