require 'scraperwiki'
require 'rubygems'
require 'mechanize'
require 'date'

use_cache = false
cache_fn = "cache.html"
url = "http://www.kingston.vic.gov.au/Planning-and-Building/Planning/Advertised-Planning-Applications"

if use_cache and File.exist?(cache_fn)
  body = ""
  File.open(cache_fn, 'r') {|f| body = f.read() }
  page = Nokogiri(body)
else
  agent = Mechanize.new
  page = agent.get(url)
  File.open(cache_fn, 'w') {|f| f.write(page.body) }
end

content = page.search('div.bodyContent')[0]
found = false
content.search('p').each do |entry|
  next unless entry.inner_text =~ /\AKP\d+/
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
  raise "Expected <ul> following " + council_reference unless ul.name == "ul"
  links = ul.search('a').map do |a|
    "http://www.kingston.vic.gov.au" + a.attribute('href')
  end

  record = {
    'description'       => "See links:\n" + links.join("\n"),
    'council_reference' => council_reference,
    'address'           => address + ", VIC",
    # These are regularly 10MB PDFs, so link to the index page in case the user clicks on it.
    'info_url'          => url,
    'comment_url'       => "mailto:info@kingston.vic.gov.au?Subject=Planning+application+" + council_reference,
    'date_scraped'      => Date.today.to_s,
  }

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Skipping already saved record " + record['council_reference']
  end
end

if not found
  raise "No entries found."
end
