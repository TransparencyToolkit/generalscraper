require 'mechanize'
require 'json'
require 'nokogiri' # Eventually move
require 'open-uri' # Eventually move
load 'parse_page.rb'

class GeneralScraper
  include ParsePage
  attr_accessor :output
  
  def initialize(operators, searchterm)
    @operators = operators
    @searchterm = searchterm
    @op_val = @operators.split(" ")[0].split(":")[1]
    
    @output = Array.new
    @urllist = Array.new
    @startindex = 10
  end

  # TODO:
  # Get proxies working
  # Choose one at random from list (list external input)
  # Remove delay
  # Script for running Google scraper

  # Separate:
  # Start agent/get URL method
  
  # Searches for links on Google
  def search
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    gform = agent.get("http://google.com").form("f")
    gform.q = @operators + " " + @searchterm
    page = agent.submit(gform, gform.buttons.first)
    categorizeLinks(page)
  end

  # Categorizes the links on results page into results and other search pages
  def categorizeLinks(page)
    page.links.each do |link|
      if (link.href.include? @op_val) && (!link.href.include? "webcache") && (!link.href.include? @operators.gsub(" ", "+"))
        siteURLSave(link)
      elsif (link.href.include? "&sa=N") && (link.href.include? "&start=")
        nextSearchPage(link)
      end
    end
  end

  # Parse and save the URLs for search results
  def siteURLSave(link)
    site_url = link.href.split("?q=")[1]
    @urllist.push(site_url.split("&")[0]) if site_url
  end

  # Process search links and go to next page
  def nextSearchPage(link)
    page_index_num = link.href.split("&start=")[1].split("&sa=N")[0]
    
    if page_index_num.to_i == @startindex
      sleep(rand(30..90)) # Eventually remove
      @startindex += 10
      agent = Mechanize.new # Need to modify this and split out
      categorizeLinks(agent.get("http://google.com" + link.href + "&filter=0"))
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    @urllist.each do |url|
      getPageData(url)
    end
    return JSON.pretty_generate(@output)
  end

  # Returns a list of search result URLs
  def getURLs
    search
    return JSON.pretty_generate(@urllist)
  end
end

g = GeneralScraper.new("site:nsa.gov", "cyberwar")
puts g.getData
