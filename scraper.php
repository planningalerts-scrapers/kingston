<?php
# City of Kingston Council scraper - ePathway
require_once 'vendor/autoload.php';
require_once 'vendor/openaustralia/scraperwiki/scraperwiki.php';

use PGuardiario\PGBrowser;
use Torann\DomParser\HtmlDom;

date_default_timezone_set('Australia/Sydney');

$url_base    = "https://online.kingston.vic.gov.au/ePathway/Production/Web/GeneralEnquiry";
$da_url      = $url_base . "/EnquirySummaryView.aspx?SortFieldNumber=5&SortDirection=Descending";
$comment_url = "mailto:info@kingston.vic.gov.au";

# Agreed Terms
$browser = new PGBrowser();
$page = $browser->get($url_base . "/EnquiryLists.aspx");
$form = $page->form();
$form->set('mDataGrid:Column0:Property', 'ctl00$MainBodyContent$mDataList$ctl03$mDataGrid$ctl02$ctl00');
$form->set('ctl00$MainBodyContent$mContinueButton', 'Next');
$page = $form->submit();

$page = $browser->get($da_url . "&PageNumber=1");
$dom = HtmlDom::fromString($page->html);

$totalNum = $dom->find("span[id=ctl00_MainBodyContent_mPagingControl_pageNumberLabel]")[0];
$totalNum = explode(" of ", trim($totalNum->plaintext));
$totalNum = (int) $totalNum[1] > 1 ? intval($totalNum[1]) : intval(1);

$nothingSaved = 0;
for ($i = 1; $i < $totalNum; $i++) {
    print ("Scraping page " .$i. " of " .$totalNum. "\n");
    $page  = $browser->get($da_url . "&PageNumber=" . $i);
    $dom   = HtmlDom::fromString($page->html);

    $applications = $dom->find("tr[class=ContentPanel], tr[class=AlternateContentPanel]");

    # The usual, look for the data set and if needed, save it
    foreach ($applications as $application) {
        # Slow way to transform the date but it works
        $date_received = trim(html_entity_decode($application->find('td',5)->plaintext));
        $date_received = explode('/', $date_received);
        $date_received = "$date_received[2]-$date_received[1]-$date_received[0]";

        $address = trim(html_entity_decode($application->find('td', 1)->plaintext)) . ', ' .
                   trim(html_entity_decode($application->find('td', 2)->plaintext)) . ', ' . 'VIC';
        $address = preg_replace('/\s+/', ' ', $address);

        # Put all information in an array
        $record = [
            'council_reference' => trim(html_entity_decode($application->find('a',0)->plaintext)),
            'address'           => $address,
            'description'       => preg_replace('/\s+/', ' ', trim(html_entity_decode($application->find('td', 3)->plaintext))),
            'info_url'          => $url_base . "/EnquiryLists.aspx",
            'comment_url'       => $comment_url,
            'date_scraped'      => date('Y-m-d'),
            'date_received'     => date('Y-m-d', strtotime($date_received))
        ];

        # Workaround to handle the council_reference changing. See
        # https://github.com/planningalerts-scrapers/kingston/pull/5#issuecomment-492858423
        if ($record['date_received'] > '2018-03-16') {
          print ("Saving record " . $record['council_reference'] . " - " . $record['address'] ."\n");
  //            print_r ($record);
          scraperwiki::save(array('council_reference'), $record);
        } else {
          print "Skipping record " . $record['council_reference'] . " because it's too old\n";
        }
    }
}

?>
