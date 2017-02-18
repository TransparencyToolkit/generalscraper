require 'nokogiri'
require 'requestmanager'
require 'json'

class TranslatePage
  def initialize(urls, requests)
    @urls = urls
    @requests = requests
    @output = Array.new
  end

  # Setup browser for translate
  def setup_browser
    @requests.get_page("https://translate.google.com")
    return @requests.get_most_recent_browser[1][0]
  end

  # First request
  def first_request(url, browser)
    # Enter URL into translate form
    translate_form = browser.find_element(id: "source")
    translate_form.send_keys(url)

    # Click the button to translate to a particular language
    click_button = browser.find_elements(:xpath, "//*[@value='es']").last
    click_button.click

    # Press Translate button, then switch back to orginal
    browser.find_element(id: "gt-submit").click
  end

  # Next request
  def nth_request(url, browser)
    browser.switch_to.default_content
    form_element = browser.find_element(name: "q")
    form_element.clear
    form_element.send_keys(url)
    form_element.submit
  end

  # Translate the pages
  def translate
    browser = setup_browser

    # Go through each link
    counter = 0
    @urls.each do |url|
      # Run translate on each page
      if counter == 0
        first_request(url, browser)
        counter+=1
      else
        nth_request(url, browser)
      end

      # Get html
      @output.push({url: url, html: get_iframe_html(browser)})
    end

    # Clean up
    @requests.close_all_browsers
    return @output
  end

  # Get iframe
  def get_iframe_html(browser)
    sleep(3)
    browser.find_element(id: "anno2").click

    # Get HTML inside the iframe
    browser.switch_to.frame(0)
    iframe_html = browser.find_element(class: "os-linux").attribute("innerHTML")
    return iframe_html
  end
end
