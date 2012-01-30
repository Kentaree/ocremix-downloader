#!/usr/bin/ruby

require 'rubygems'
require 'ostruct'
require 'optparse'
require 'net/http'
require 'digest/md5'
require 'cgi'
require 'peach'

ConfigFile = File.expand_path("~/.ocr_downloader.conf")
BaseUrl = "http://ocremix.org/remix/OCR"

options = OpenStruct.new
options.verbose = false
options.processes = 1

opts = OptionParser.new do |opts|
  opts.on('-f', '--from [START]', Integer, 'Start song to download') { |from| options.from = from }
  opts.on('-t', '--to END', Integer, 'Last song to download') { |to| options.to = to }
  opts.on('-v', '--[no-]verbose', 'Output debug info') { |v| options.verbose = v }
  opts.on('-p', '--processes [COUNT]', Integer, 'Amount of processes to use') { |p| options.processes = p }
end 

opts.parse!
if options.from == nil && File.exists?(ConfigFile)
  File.open(ConfigFile,"r") do |config|
      from = config.gets()
      options.from = from.chomp.to_i if from != nil
      puts "Starting from number #{from}"
  end
end

(options.from..options.to).to_a.peach(options.processes) do |i|
  url = sprintf("%s%05d/",BaseUrl,i)
  puts url if options.verbose
  uri = URI.parse(url)
  result = Net::HTTP.get(uri)
  matches = result.scan(/MD5 Checksum: <\/strong>([^<]+)</)
  if matches == nil || matches[0] == nil
    puts sprintf("Skipping OCR%05d",i) if options.verbose
    next
  end

  md5 = matches[0][0].chomp
  puts "Md5: #{md5}" if options.verbose
    
  matches = result.scan(/<a href="([^"]+)">Download from/)
  success = false
  matches.each do |match|
    url = match[0]
    puts "Url: #{url}, type: #{url.class}" if options.verbose
    uri = URI.parse(url)

    scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI::split(url)
    Net::HTTP.start(host) do |http|
      result = http.get(path)
      filename = sprintf("OCR%05d-%s",i,CGI::unescape(File.basename(path)))
      puts "Saving to filename #{filename}" if options.verbose
      open(filename,"w") do |file|
        file.write(result.body)
      end
      digest = Digest::MD5.hexdigest(File.read(filename))
      puts "Expected md5: #{md5}, actual: #{digest}" if options.verbose
      if md5 == digest
        puts "Download successful!" if options.verbose
        success = true
      end
    end
    break if success
  end

  File.open(ConfigFile,"w") do |config|
    config.puts(i+1)
  end
end
   
