default: _site
	jekyll build

serve:
	jekyll serve --port 3000

dependencies:
	gem install jekyll bundler aws-sdk-s3

svgs:
	scripts/cleanup-svgs.sh assets/images/*.svg

publish:
	vercel --prod

.PHONY: publish
