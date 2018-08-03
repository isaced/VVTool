#!/usr/bin/ruby

require "vvtool/version"
require "live_server.rb"
require 'Thor'

module VVTool
    class CLI < Thor
      desc "run", "启动 VirtualView 实时预览服务"
      def runLiveServer
        live_server_run
      end

      desc "about", "关于"
      def about
        puts "这个命令主要用于 VirtualView 实时预览 - https://github.com/isaced/VVTool"
      end

      map %w[--version -v] => :__print_version
      desc "--version, -v", "版本"
      def __print_version
        puts VVTool::VERSION
      end
    end
end

VVTool::CLI.start(ARGV)