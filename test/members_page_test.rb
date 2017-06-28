# frozen_string_literal: true

require_relative './test_helper'
require_relative '../lib/members_page'

describe MembersPage do
  around { |test| VCR.use_cassette(File.basename(url), &test) }
  let(:subject) { MembersPage.new(response: Scraped::Request.new(url: url).response) }
  let(:url) { 'https://www.parliament.gh/mps?az&filter=all' }

  describe 'Member cards' do
    it 'returns the expects number of member cards' do
      subject.member_cards.count.must_equal 10
    end

    it 'returns the expected member data' do
      subject.member_cards.first.must_equal(
        id:           '169',
        name:         'ABDUL-AZIZ MOHAMMED',
        party:        'NDC',
        constituency: 'Mion Constituency',
        source:       'https://www.parliament.gh/mps?mp=169'
      )
    end
  end

  describe 'Members pages urls' do
    it 'returns a list of members page urls' do
      subject.members_pages_urls.count.must_equal 28
    end

    it 'returns the expected url' do
      subject.members_pages_urls.first.must_equal 'https://www.parliament.gh/mps?az&P=0'
    end
  end
end
