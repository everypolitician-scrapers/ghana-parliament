#!/bin/env ruby
# encoding: utf-8

require 'date'
require 'nokogiri'
require 'scraped'
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

class MembersPage < Scraped::HTML
  field :mp_urls do
    noko.css('#mid_content_conteiner .mp_repeater').map do |mpbox|
      mpbox.at_css('a[@href*="/parliamentarians/"]/@href').text
    end
  end

  field :next_page do
    noko.css('span.content_txt').xpath('.//a[contains(text(),">")]/@href').text
  end
end

def scrape_list(url)
  warn "Getting #{url}"
  page = MembersPage.new(response: Scraped::Request.new(url: url).response)
  page.mp_urls.each do |mp_url|
    scrape_mp(mp_url)
  end

  scrape_list(page.next_page) unless page.next_page.empty?
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
