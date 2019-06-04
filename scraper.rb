require "epathway_scraper"

EpathwayScraper.scrape(
  "https://online.kingston.vic.gov.au/ePathway/Production",
  list_type: :all_year, max_pages: 9, year: 2019
) do |record|
  # Add state on to the address
  record["address"] += ", VIC"
  EpathwayScraper.save(record)
end
