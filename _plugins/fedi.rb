module Jekyll
  module Fedi
    # Takes a handle of the form "@someone@toot.example.com"
    # and transforms it to a profile URL of the form
    # "https://toot.example.com/@someone".
    def fedi_to_https(input)
      input
        .sub('@', '')
        .split('@')
        .reverse
        .join('/@')
        .prepend('https://')
    end
  end
end

Liquid::Template.register_filter(Jekyll::Fedi)
