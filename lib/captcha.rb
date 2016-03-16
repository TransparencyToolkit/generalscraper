require 'rmagick'
require 'curb'
require 'two_captcha'
include Magick

class Captcha
  def initialize(requests, solver_details)
    @requests = requests
    @captcha_key = solver_details[:captcha_key]
  end

  # Solves the captcha
  def solve
    take_screenshot
    crop_screenshot
    @captcha_solution = get_captcha_solved
    submit_captcha_solution
    delete_screenshots
  end

  # Have the captcha solved
  def get_captcha_solved
    client = TwoCaptcha.new(@captcha_key)
    begin
      captcha = client.decode!(file: File.open(@time_name+"_cropped.png"))
    rescue Exception # If it times out
      get_captcha_solved
    end
    return captcha.text
  end

  # Submit the captcha solution
  def submit_captcha_solution
    browser =  @requests.get_most_recent_browser[1][0]
    element = browser.find_element(id: "captcha")
    element.send_keys(@captcha_solution)
    element.submit
  end

  # Takes a screenshot of captcha in browser
  def take_screenshot
    @time_name = Time.now.to_s.gsub(" ", "").gsub("-", "").gsub(":", "").gsub("-", "")
    @requests.get_most_recent_browser[1][0].save_screenshot(@time_name+".png")
  end

  # Crops the screenshot to be mostly just the CAPTCHA
  def crop_screenshot
    captcha_image = Image.read(@time_name+".png").first
    width = captcha_image.columns
    height = captcha_image.rows
    cropped_captcha = captcha_image.crop(0, 0, width, height/2)
    cropped_captcha.write(@time_name+"_cropped.png")
  end

  # Deletes the screenshot images
  def delete_screenshots
    File.delete(@time_name+".png", @time_name+"_cropped.png")
  end
end
