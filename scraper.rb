require 'scraperwiki'
require 'rubygems'
require 'mechanize'
require 'date'

cache_fn = "cache.html"

if File.exist?(cache_fn)
  body = ""
  File.open(cache_fn, 'r') {|f| body = f.read() }
  page = Nokogiri(body)
else
  agent = Mechanize.new
  url = "http://www.kingston.vic.gov.au/Planning-and-Building/Planning/Advertised-Planning-Applications"
  page = agent.get(url)
  File.open(cache_fn, 'w') {|f| f.write(page.body) }
end

content = page.search('div.bodyContent')[0]
found = false
content.search('p').each do |entry|
  if not entry.inner_text =~ /\AKP\d+/
    next
  end
  found = true

  # <p> contains reference and address.
  council_reference, address = entry.inner_text.split(" - ", 2)
  # "No. 1 - No. 2 Example Road, Suburb:"
  address.sub!(/\ANo\. /, '')
  address.sub!(/ - No. /, '-')
  address.sub!(/:\Z/, '')
  # "Shop 1, No. 23 Example Road"
  address.sub!(/, No\. /, ', ')

  # <p> is followed by a list of links to PDFs.
  ul = entry.next_element
  if ul.name != "ul"
    raise "Expected <ul> following " + council_reference
  end
  links = []
  ul.search('a').each do |a|
    links.push("http://www.kingston.vic.gov.au" + a.attribute('href'))
  end

  record = {
    'description'       => "See links:\n" + links.join("\n"),
    'council_reference' => council_reference,
    'address'           => address + ", VIC",
    'info_url'          => links[0],
    'comment_url'       => "mailto:info@kingston.vic.gov.au?Subject=Planning+application+" + council_reference,
    'date_scraped'      => Date.today.to_s,
  }

  if ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? 
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Skipping already saved record " + record['council_reference']
  end
end

if not found
  raise "No entries found."
end
