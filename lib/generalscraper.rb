require 'json'
require 'nokogiri'
require 'mechanize'
require 'requestmanager'
require 'pry'

load 'parse_page.rb'
load 'captcha.rb'

class GeneralScraper
  include ParsePage
  
  def initialize(operators, searchterm, requests, solver_details, cm_hash)
    @operators = operators
    @searchterm = searchterm
    @op_val = @operators.split(" ")[0].split(":")[1]
    @requests = requests
    @solver_details = solver_details
    
    @output = Array.new
    @urllist = Array.new
    @startindex = 10

    # Handle crawler manager info
    @cm_url = cm_hash[:crawler_manager_url] if cm_hash
    @selector_id = cm_hash[:selector_id] if cm_hash
  end

  # Searches for links on Google
  def search
    check_results(@requests.get_page("http://google.com", @operators + " " + @searchterm),
                  "http://google.com", (@operators + " " + @searchterm))
  end

  # Check that page with links loaded
  def check_results(page, *requested_page)
    if page.include?("To continue, please type the characters below:")
      # Solve CAPTCHA if enabled
      if @solver_details
        c = Captcha.new(@requests, @solver_details)
        c.solve
        
        # Proceed as normal
        sleep(1)
        check_results(@requests.get_updated_current_page)
        
      else # Restart and try again if CAPTCHA-solving not enabled
        @requests.restart_browser
        check_results(@requests.get_page(requested_page), requested_page)
      end
    else # No CAPTCHA found :)
      begin
        navigate_save_results(page)
      rescue Exception
        @requests.restart_browser
        check_results(@requests.get_page(requested_page), requested_page)
      end
    end
  end

  # Gets the links from the page that match css selector in block
  def get_links(page, &block)
    html = Nokogiri::HTML(page)

    # Get array of links
    return yield(html).inject(Array.new) do |link_arr, al|
      begin
        link_arr.push(al["href"])
      rescue
        
      end
     
      link_arr
    end
  end

  # Categorizes the links on results page into results and other search pages
  def navigate_save_results(page)
    # Save result links for page
    result_links = get_links(page) {|html| html.css("h3.r").css("a")}
    result_links.each do |link|
      site_url_save(link)
    end

    # Go to next page
    next_pages = get_links(page) {|html| html.css("#pnnext")}
    next_pages.each do |link|
      next_search_page("google.com"+link)
    end
  end
  
  # Parse and save the URLs for search results
  def site_url_save(link)
    @urllist.push(link)
  end

  # Process search links and go to next page
  def next_search_page(link)
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
      report_results(getPageData(url), url)
    end

    @requests.close_all_browsers
  end

  # Figure out how to report results
  def report_results(results, link)
    if @cm_url
      report_incremental(results, link)
    else
      report_bulk(results)
    end
  end

  # Report results back to Harvester incrementally
  def report_incremental(results, link)
    curl_url = @cm_url+"/relay_results"
    c = Curl::Easy.http_post(curl_url,
                             Curl::PostField.content('selector_id', @selector_id),
                             Curl::PostField.content('status_message', "Collected " + link),
                             Curl::PostField.content('results', JSON.pretty_generate(results)))
  end

  # Add page hash to output for bulk reporting
  def report_bulk(results)
    @output.push(results)
  end
  

  # Returns a list of search result URLs
  def getURLs
    search
    @requests.close_all_browsers
    return JSON.pretty_generate(@urllist)
  end

  # Get the JSON of all the data
  def get_json_data
    return JSON.pretty_generate(@output)
  end
end

