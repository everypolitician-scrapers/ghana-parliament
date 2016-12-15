#!/bin/env ruby
# encoding: utf-8

require 'date'
require 'nokogiri'
require 'scraperwiki'

require 'scraped_page_archive/open-uri'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def datefrom(date)
  return if date.empty?
  Date.parse(date)
end

def scrape_list(url)
  warn "Getting #{url}"
  noko = noko_for(url)

  noko.css('#mid_content_conteiner .mp_repeater').each do |mpbox|
    mp_url = mpbox.at_css('a[@href*="/parliamentarians/"]/@href').text
    scrape_mp(mp_url)
  end

  next_page = noko.css('span.content_txt').xpath('.//a[contains(text(),">")]/@href')
  scrape_list(next_page.text) unless next_page.empty?
end

def scrape_mp(url)
  box = noko_for(url).css('.content_text_column')

  data = { 
    id: url[/(\d+)$/, 1],
    name: box.at_css('.left_subheaders').text,
    image: box.at_css('img[src*="/userfiles/"]/@src').text,
    # TODO split these up again
    constituency: box.at_css('div.content_subheader').text.strip.match(/MP\s+for\s+(.*)\s+constituency,\s*(.*)/).captures.join(", "),
    party: box.xpath('//strong[contains(text(),"Party")]/ancestor::td').last.css('span.content_txt').last.text.gsub(/[[:space:]]+/,' '),
    religion: box.xpath('//strong[contains(text(),"Religion")]/following::td').first.text,
    birth_date: datefrom(box.xpath('//strong[contains(text(),"Date of Birth")]/following::td').first.text).to_s,
    email: box.xpath('//strong[contains(text(),"Email")]/following::td').first.text,
    term: 6,
  }
  data[:party].gsub!(/\s*\(\s*M(ajor|inor)ity\s*\)\s*/,'')
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  # The profile <img> for one MP has an erroneous src attribute
  # http://www.parliament.gh/parliamentarians/105
  # src="/userfiles/mps/404error.php.txt.txt"
  # It doesn't point to the member's image, so we don't want
  # to capture it.
  data[:image] = nil if data[:image].include?('404error')
  # puts data
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list 'http://www.parliament.gh/parliamentarians'

# http://en.wikipedia.org/w/index.php?title=MPs_elected_in_the_Ghanaian_parliamentary_election,_2012&oldid=626903925
term = {
  id: 6,
  name: "Sixth Parliament of the Fourth Republic",
  source: "http://www.parliament.gh/publications/53/732",
  start_date: '2013-01-07',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

