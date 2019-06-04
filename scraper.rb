require "epathway_scraper"

EpathwayScraper.scrape_and_save(
  "https://online.kingston.vic.gov.au/ePathway/Production",
  list_type: :all_year, max_pages: 9, year: 2019
)
