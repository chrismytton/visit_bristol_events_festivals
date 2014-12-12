require 'nokogiri'
require 'date'
require 'scraperwiki'
require 'digest'
require 'uri'

ScraperWiki.config = {db: 'data.sqlite', default_table_name: 'data'}

def absolute_url(base_url, url)
  base_url = URI.parse(base_url)
  url = URI.parse(url)
  base_url.path = url.path
  base_url.query = url.query
  base_url.to_s
end

url = 'http://visitbristol.co.uk/things-to-do/events-and-festivals'
html = ScraperWiki.scrape(url)
doc = Nokogiri.HTML(html)
events = doc.css('.Highlight').map do |highlight|
  name = highlight.at_css('h2.Name a')
  title = name.text.strip
  image = absolute_url(url, highlight.at_css('.Image noscript img')['src'])
  link = absolute_url(url, name['href'])
  date_from = Date.parse(highlight.at_css('.Dates .From').text.strip)
  date_to = Date.parse(highlight.at_css('.Dates .To').text.strip)
  id = Digest::MD5.new
  id.update(title)
  id.update(date_from.to_s)
  id.update(date_to.to_s)
  {
    id: id.hexdigest,
    title: title,
    image: image,
    link: link,
    date_from: date_from,
    date_to: date_to,
  }
end

events.each do |event|
  if (ScraperWiki.select("* from data where id = ?", event[:id]).any? rescue false)
    puts "Existing event found #{event[:id]} #{event[:title]}"
    next
  end
  puts "Creating new event #{event[:id]} #{event[:title]}"
  ScraperWiki.save_sqlite([:id], event)
end
