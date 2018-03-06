#!/usr/bin/ruby

require 'rubygems'
require 'ostruct'
require 'optparse'
require 'net/http'
require 'digest/md5'
require 'cgi'
require 'peach'
require 'open-uri'

CONFIG_FILE = File.expand_path("~/.ocr_downloader.conf")
BASE_URL = "http://ocremix.org/remix/OCR"

$options = OpenStruct.new(:verbose => false, :processes => 1, :ocr_nums => false)

def log(message)
  puts message if $options.verbose
end

OptionParser.new do |opts|
  opts.banner = "Usage: ocremix.org [options] [destination]"

  opts.on('-f', '--from [START]', Integer, 'Start song to download') {|from| $options.from = from}
  opts.on('-t', '--to END', Integer, 'Last song to download') {|to| $options.to = to}
  opts.on('-v', '--[no-]verbose', 'Output debug info') {|v| $options.verbose = v}
  opts.on('-p', '--processes [COUNT]', Integer, 'Amount of processes to use') {|p| $options.processes = p}
  opts.on('-n', 'Prepend OCR number to filename') {|n| $options.ocr_nums = true}
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

destination = ARGV.empty? ? Dir.pwd : ARGV.join
Dir.chdir destination

if $options.from == nil && File.exists?(CONFIG_FILE)
  File.open(CONFIG_FILE, "r") do |config|
    from = config.gets
    $options.from = from.chomp.to_i if from != nil
    puts "Starting from number #{from}"
  end
end

($options.from..$options.to).to_a.peach($options.processes) do |i|
  url = sprintf("%s%05d/", BASE_URL, i)
  log(url)

  begin
    result = open(url) do |f|
      f.read
    end
  rescue OpenURI::HTTPError => error
    puts "Couldn't find OCR #{i}, status code #{error.io.status}"
    next
  end

  matches = result.scan(/MD5 Checksum: <\/strong>([^<]+)</)
  if matches == nil || matches[0] == nil
    log sprintf("Skipping OCR%05d", i)
    next
  end

  md5 = matches[0][0].chomp
  log "Md5: #{md5}"

  matches = result.scan(/<a href="([^"]+)">Download from/)
  success = false
  matches.each do |match|
    url = match[0]
    log "Url: #{url}, type: #{url.class}"
    _, _, host, _, _, path, _, _, _ = URI::split(url)
    Net::HTTP.start(host) do |http|
      result = http.get(path)
      if $options.ocr_nums
        filename = sprintf("OCR%05d-%s", i, CGI::unescape(File.basename(path)))
      else
        filename = sprintf(CGI::unescape(File.basename(path)))
      end

      if File.exists?(filename)
        log "File exists, comparing checksum"
        digest = Digest::MD5.hexdigest(File.read(filename))
        if md5 == digest
          puts "File already exists with same checksum, skipping"
          success = true
          break
        end
      end

      log "Saving to filename #{filename}"
      open(filename, "wb") do |file|
        file.write(result.body)
      end
      digest = Digest::MD5.hexdigest(File.read(filename))
      log "Expected md5: #{md5}, actual: #{digest}"
      if md5 == digest
        log "Download successful!"
        success = true
      end
    end
    break if success
  end

  File.open(CONFIG_FILE, "w") do |config|
    config.puts(i + 1)
  end
end

