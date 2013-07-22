require 'net/http'
require 'rexml/document'

def gif collection, keyword
  query = Regexp.new(keyword, Regexp::IGNORECASE)

  cache_file = "cache/#{File.basename(collection)}.xml"
  cache_time = 300

  Dir.mkdir('cache') if !File.directory?('cache')

  if File.exists?(cache_file) && File.mtime(cache_file) > Time.now - cache_time
    xml_data = File.read(cache_file)
  else
    xml_data = Net::HTTP.get_response(URI.parse("#{collection}.rss")).body
    File.open(cache_file, 'w') { |file| file.write xml_data }
  end

  rss = REXML::Document.new(xml_data)
  results = REXML::Document.new('<items/>')

  rss.each_element('rss/channel/item') do |item|
    if (links = item.get_elements('link')).size > 0 && (query == // || query.match(item.to_s))
      link = links[0].text

      result = REXML::Element.new 'item', results.root
      result.add_attribute 'arg', link
      result.add_attribute 'autocomplete', link

      title = REXML::Element.new 'title', result
      title.text = item.get_elements('title')[0].text

      subtitle = REXML::Element.new 'subtitle', result
      subtitle.text = link

      icon = REXML::Element.new 'icon', result
      icon.add_attribute 'type', 'filetype'
      icon.text = File.extname link
    end
  end
  
  return results.to_s
end