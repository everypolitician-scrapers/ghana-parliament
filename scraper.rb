#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def member_data(url)
  page = scrape url => MembersPage
  page.member_cards.map do |mp_card|
    mp_card.merge((scrape mp_card[:source] => MemberPage).to_h)
  end
end

starting_url = 'https://www.parliament.gh/mps?az&filter=all'
data = (scrape starting_url => MembersPage).members_pages_urls.flat_map do |url|
  member_data(url)
end
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[id], data)
