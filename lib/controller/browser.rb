require 'watir'
require 'watir-webdriver'
include Selenium
require 'fileutils'
require 'headless'
require_relative '../helper'

class Browser

  def initialize(baseurl, urls, resolutions, path, headless, wait, cookies = [], localStorage = [])
    @absolute_image_path = path
    FileUtils.mkdir_p @absolute_image_path
    @baseurl = baseurl
    @urls = urls
    @resolutions = resolutions
    @headless = headless
    @wait = wait

    if cookies
      @cookies = cookies
    else
      @cookies = []
    end

    if localStorage
      @localStorage = localStorage
    else
      @localStorage = []
    end
  end

  def record(version)
    browser_loader
    @urls.each do |url|
      @resolutions.each do |width|
        screenshot_recorder(width, url, version)
      end
    end
  end

  def end
    begin #Timeout::Error
      Timeout::timeout(10) { @browser.close }
    rescue Timeout::Error
      browser_pid = @browser.driver.instance_variable_get(:@bridge).instance_variable_get(:@service).instance_variable_get(:@process).pid
      ::Process.kill('KILL', browser_pid)
      sleep 1
    end
    sleep 5 # to prevent xvfb to freeze
  end

  private

  def browser_loader
    if @headless
      @browser = Watir::Browser.new :phantomjs
    else
      @browser = Watir::Browser.new :firefox
    end
  end

  def screenshot_recorder(width, url, version)
    filename = Helper.filename(@absolute_image_path, url, width, version)
    @browser.driver.manage.window.resize_to(width, 1000)

    url = Helper.url(@baseurl, url)

    if @cookies.any? || @localStorage.any?
      # load url first before setting cookies and/or localStorage values
      @browser.goto url

      if @cookies.any?
        @browser.cookies.clear
        @cookies.each do |cookie|
          @browser.cookies.add(cookie[:name], cookie[:value], domain: cookie[:domain], path: cookie[:path], expires: Time.now + 7200, secure: cookie[:secure])
        end
      end

      if @localStorage.any?
        @localStorage.each do |key, value|
          # Generate javascript for localStorage.setItem, escaping single quotes in key and value
          stmt = "localStorage.setItem('" + key.gsub("'", "\\\\'") + "','" + value.gsub("'", "\\\\'") + "')";
          @browser.execute_script(stmt)
        end
      end
    end

    @browser.goto url

    sleep @wait if @wait
    @browser.screenshot.save( File.expand_path(filename))
  end

end
