default: _site
	$(eval TMP := $(shell mktemp))
	cp _site/vercel.json $(TMP)
	bundle exec jekyll build
	mv $(TMP) _site/vercel.json

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
