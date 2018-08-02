#!/usr/bin/ruby

require 'fileutils'
require 'pathname'
require 'webrick'
require 'Listen'
require 'base64'
require 'json'
require 'net/http'

# 路径
PropertiesFileName = 'templatelist.properties'
CompilerFileName = '.compiler.jar'
TemplatesPath = Dir.pwd
TemplatePath = File.join(TemplatesPath, 'template')
VVBuildPath = File.join(TemplatesPath, 'build')
VVBuildLogFilePath = File.join(TemplatesPath, '.vvbuild.log')
VVCompilerFilePath = File.join(TemplatesPath, CompilerFileName)
PropertiesFilePath = File.join(TemplatesPath, PropertiesFileName)
DirFilePath = File.join(TemplatesPath, '.dir')

VVCompilerDownloadURL = 'https://raw.githubusercontent.com/alibaba/virtualview_tools/master/compiler-tools/TemplateWorkSpace/compiler.jar'

$buildCount = 1

module VVPrepare
  # 拷贝 xml 准备编译
  def self.copyXML(copyTemplatePath)
    FileUtils.rm_rf TemplatePath
    FileUtils.mkdir_p TemplatePath
    FileUtils.cp Dir.glob("#{copyTemplatePath}/**/*.xml"), TemplatePath
  end

  # 生成 templatelist.properties 文件
  def self.generateProperties()
    nowTimestamp = Time.now.to_i
    propertiesContent = Dir.entries(TemplatePath).reject { |f| File.directory? f } .map { |f| 
      filename = File.basename f, '.*'
      "#{filename}=#{filename},#{nowTimestamp}"
    }
    File.open(PropertiesFilePath, 'w+') { |f|
        propertiesContent.each { |e| f.puts e }
    }
  end

  def self.checkVVCompiler()
    if File.exist? VVCompilerFilePath
      puts 'Check VV compiler ok.'
    else
      puts 'Start downloading VV compiler.jar...'
      File.write(VVCompilerFilePath, Net::HTTP.get(URI.parse(VVCompilerDownloadURL)))
      if File.exist? VVCompilerFilePath
        puts 'VV compiler.jar download success.'
      else
        puts 'VV compiler.jar download fail.'
        exit
      end
    end
  end

  # 编译
  def self.vvbuild()
    system "java -jar #{VVCompilerFilePath} jarBuild > #{VVBuildLogFilePath}"
  end

  def self.generateDataJSON(aTemplatesPath)
    # 生成每个模版对应的 data.json
    templateNameList = []
    Pathname.new(aTemplatesPath).children.push(aTemplatesPath).each { | aTemplatePath |
      templateName = File.basename aTemplatePath, '.*'

      next if not File.directory? aTemplatePath
      next if not File.exist?(File.join(aTemplatePath, "#{templateName}.json"))
      next if templateName.start_with? '.'

      # 把所有模版名记录下来
      templateNameList << templateName

      # 获取这个模版目录下所有 xml 的编译二进制 Base64 列表
      xmlBase64List = []
      Dir.glob(File.join(aTemplatePath, '**/*.xml')).each { | xmlFilePath |
        xmlFileName = File.basename xmlFilePath, '.*'

        # 获取这个 xml 的 .out -> base64
        xmlBuildOutPath = File.join(VVBuildPath, "out/#{xmlFileName}.out")
        xmlBase64String = Base64.strict_encode64(File.open(xmlBuildOutPath, "rb").read)
        xmlBase64List << xmlBase64String
      }

      # 读取模版参数 JSON
      templateParams = {}
      templateParamsJSONPath = File.join(aTemplatePath, "#{templateName}.json")
      if File.exist?(templateParamsJSONPath)
        templateParams = JSON.parse(File.read(templateParamsJSONPath))
      end
      

      # 合并 data.json （HTTP Server 读取）
      if xmlBase64List.count > 0
        dataHash = {'templates': xmlBase64List, 'data': templateParams,}
        dataJSONPath = File.join(aTemplatePath, "data.json")
        File.open(dataJSONPath, "w") { |f|
          f.write(JSON.pretty_generate dataHash)
        }
      end
    }

    # 生成模版目录结构 .dir（HTTP Server 读取）
    File.open(DirFilePath, "w") { |f|
      f.write(JSON.pretty_generate templateNameList)
    }
  end

  def self.clean()
    FileUtils.rm_rf TemplatePath
    FileUtils.rm_rf VVBuildPath
    FileUtils.rm_f PropertiesFilePath
  end
end

# 第一次
def firstBuild()
  # 0. Clean
  VVPrepare.clean

  # 0.1 检查编译器 - 没有则下载
  VVPrepare.checkVVCompiler()

  puts 'Start build templates...'

  # 1. 拷贝出来集中所有 .xml 模版文件
  VVPrepare.copyXML TemplatesPath

  # 2. 生成 compiler.jar 编译所需的 templatelist.properties 文件
  VVPrepare.generateProperties

  # 3. 编译
  VVPrepare.vvbuild

  # 4. 生成 data.json
  VVPrepare.generateDataJSON TemplatesPath

  # 5. Clean
  VVPrepare.clean

  puts 'All templates build finished.'
end

# 单次编译
public def singleBuild(aTemplatePath)
  # 0. Clean
  VVPrepare.clean

  # 1. 拷贝出来集中所有 .xml 模版文件
  VVPrepare.copyXML aTemplatePath


  # 2. 生成 compiler.jar 编译所需的 templatelist.properties 文件
  VVPrepare.generateProperties

  # 3. 编译
  VVPrepare.vvbuild

  # 4. 生成 data.json
  VVPrepare.generateDataJSON aTemplatePath

  # 5. Clean
  VVPrepare.clean
end

def live_server_run
    firstBuild()

    puts TemplatesPath
    # HTTP Server
    Thread.new {
      http_server = WEBrick::HTTPServer.new(
        :Port => 7788,  
        :DocumentRoot => TemplatesPath,
        :Logger => WEBrick::Log.new(VVBuildLogFilePath),
        :AccessLog => []
        )
      http_server.start
    }

    puts 'Start HTTP server: http://127.0.0.1:7788'

    # File Watch
    listener = Listen.to(TemplatesPath, only: [/\.xml$/, /\.json$/]) { |modified, added, removed|
      (modified + added).each { |filePath|
        thisTemplatePath = Pathname.new(filePath).dirname
        thisTemplateName = File.basename filePath, '.*'
        thisTemplateNameAndExt = File.basename filePath
        next if thisTemplateNameAndExt == 'data.json'
        puts "[#{ Time.now.strftime("%H:%M:%S") }] Update template: #{thisTemplateName} (#{thisTemplateNameAndExt})"

        self.singleBuild thisTemplatePath
        VVPrepare.clean
        $buildCount += 1
      }
    }.start

    puts 'Start Watching...'
    puts ''

    trap "SIGINT" do
      puts ''
      puts "Bye, see you next time, build count: #{$buildCount}"
      
      # clean
      FileUtils.rm_f VVBuildLogFilePath
      FileUtils.rm_f DirFilePath

      exit 130
    end

    sleep
end