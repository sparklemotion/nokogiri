#
#  this patch works around https://github.com/seattlerb/hoe/issues/103
#
require "hoe"

class Hoe
  alias_method :old_parse_urls, :parse_urls

  def parse_urls(text)
    return urls unless urls.empty?
    old_parse_urls(text)
  end
end
