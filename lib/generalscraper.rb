require 'json'
require 'nokogiri'
require 'mechanize'
require 'requestmanager'
require 'pry'

load 'parse_page.rb'

class GeneralScraper
  include ParsePage
  
  def initialize(operators, searchterm, requests)
    @operators = operators
    @searchterm = searchterm
    @op_val = @operators.split(" ")[0].split(":")[1]
    @requests = requests
    
    @output = Array.new
    @urllist = Array.new
    @startindex = 10
  end

  # Searches for links on Google
  def search
    check_results(@requests.get_page("http://google.com", @operators + " " + @searchterm),
                  "http://google.com", (@operators + " " + @searchterm))
  end

  # Check that page with links loaded
  def check_results(page, *requested_page)
    if page.include?("To continue, please type the characters below:")
      @requests.restart_browser
      check_results(@requests.get_page(requested_page), requested_page)
    else
      categorizeLinks(page)
    end
  end

  # Gets the links from the page
  def getLinks(page)   
    html = Nokogiri::HTML(page)

    # Get array of links
    return html.css("a").inject(Array.new) do |link_arr, al|
      begin
        link_arr.push(al["href"])
      rescue
        
      end
     
      link_arr
    end
  end

  # Categorizes the links on results page into results and other search pages
  def categorizeLinks(page)
    links = getLinks(page)

    # Categorize as results or search pages
    links.each do |link| 
      if link
        if isResultLink?(link)
          siteURLSave(link)
        elsif isSearchPageLink?(link)
          nextSearchPage("google.com"+link)
        end
      end
    end
  end

  # Determines if url is link to search result
  def isResultLink?(link)
    return (link.include? @op_val) &&
           (!link.include? "webcache") &&
           (!link.include? @operators.gsub(" ", "+")) &&
           (!link.include?("translate.google"))
  end

  # Determines if URL is link to next search page
  def isSearchPageLink?(link)
    return (link.include? "&sa=N") && (link.include? "&start=")
  end

  
  # Parse and save the URLs for search results
  def siteURLSave(link)
    @urllist.push(link)
  end

  # Process search links and go to next page
  def nextSearchPage(link)
    page_index_num = link.split("&start=")[1].split("&sa=N")[0]
  
    if page_index_num.to_i == @startindex
      @startindex += 10
      check_results(@requests.get_page(link), link)
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    @urllist.each do |url|
      getPageData(url)
    end

    @requests.close_all_browsers
    return JSON.pretty_generate(@output)
  end

  # Returns a list of search result URLs
  def getURLs
    search
    @requests.close_all_browsers
    return JSON.pretty_generate(@urllist)
  end
end
