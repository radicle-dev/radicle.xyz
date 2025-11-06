module Jekyll
  module Explorer
    def explore(input)
      base = "https://app.radicle.xyz/nodes"
      if input.include?(' ')
        prefix, suffix = input.split(' ', 2)
        "#{base}/#{prefix}/#{suffix}"
      else
        "#{base}/iris.radicle.xyz/#{input}"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Explorer)
