require "epathway_scraper"

EpathwayScraper.scrape_and_save(
  "https://online.kingston.vic.gov.au/ePathway/Production",
  list_type: :all_this_year, state: "VIC"
)
