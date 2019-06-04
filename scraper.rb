require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
year = ENV["MORPH_PERIOD"].to_i

puts "Getting data in year '#{year}', changable via MORPH_PERIOD environment"

records = []
EpathwayScraper.scrape(
  "https://online.kingston.vic.gov.au/ePathway/Production",
  list_type: :all_year, year: year
) do |record|
  # Add state on to the address
  record["address"] += ", VIC"
  record["address"] = record["address"].squeeze(" ")
  if record["address"] == ", VIC"
    record["address"] = ", , VIC"
  end
  # Format the description like the php scraper
  record["description"] = record["description"].gsub("\n", " ").squeeze(" ")
  records << record
  puts "Scraped record #{record["council_reference"]}"
end

# Only keep the most recent 270 to match the php scraper
records.sort{|a,b| b["date_received"] <=> a["date_received"]}[0...270].each do |record|
  EpathwayScraper.save(record)
end
