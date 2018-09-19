#!/usr/bin/ruby

require 'net/http'
require 'json'
require_relative "vvtool/version.rb"

RubyGemsLatestVersionURL = 'https://rubygems.org/api/v1/versions/vvtool/latest.json'

def get_remote_version
  begin
    Thread.new {
      response = Net::HTTP.get(URI(RubyGemsLatestVersionURL))
      response = JSON.parse(response)
      yield response['version']
    }
  end
end

def check_new_version
  get_remote_version { |remoteVersion| 
    currentVersion = VVTool::VERSION
    if currentVersion < remoteVersion
      puts "VVTool 发现新版本 v#{remoteVersion}（当前 v#{currentVersion}），可以通过命令 `sudo gem install vvtool` 升级"
    end
  }
end
