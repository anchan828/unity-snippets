require 'json'
require 'fileutils'
require 'securerandom'

class Snippet
  @@var = ""

  class << self
    def write(path, methods)
      _path = File.dirname path
      FileUtils.mkdir_p(_path) unless FileTest.exist?(_path)
      File.write(path, to_text(methods.map { |method| new method }))
    end
  end

  def initialize(data)

    @isStatic= data['isStatic']
    @namespace = data['namespace']
    @name = data['name']
    @returnType= data['returnType']

    @args = []

    d_args = data['args']
    if d_args != nil
      @args = d_args.each_with_index.map { |arg, i| Arg.new(arg, i) }
    end
  end

  def variable(index)
    @@var.gsub("[i]", index.to_s)
  end

end

class Arg
  def initialize(data, index)
    @type = data['type']
    @name = data['name']
    @index = index
  end

  def name
    @name
  end

  def type
    @type
  end
end

class Monodevelop < Snippet
  @@var = "$name[i]$"

  class << self

    def to_text(snippets)
      text = <<EOS
<?xml version="1.0" encoding="utf-8"?>
<CodeTemplates version="3.0">
EOS

      text += snippets.join("")

      text += "</CodeTemplates>"
    end
  end

  def to_s
    template =<<EOS
  <CodeTemplate version="2.0">
    <Header>
      <_Group>UnityC#</_Group>
      <MimeType>text/x-csharp</MimeType>
      <Version>1.0</Version>
      <_Description>Message</_Description>
      <TemplateType>SurroundsWith,Expansion</TemplateType>
      <Shortcut>#{@name}</Shortcut>
    </Header>
EOS

    if @args.length != 0
      template += <<EOS
    <Variables>
EOS

      args = []

      @args.each_index { |i|
        template += <<EOS
        <Variable name="name#{i}">
            <Default>#{@args[i].name}</Default>
        </Variable>
EOS
        args.push "#{@args[i].type} #{variable(i)}"

      }
      template += <<EOS
    </Variables>
EOS
    else
      template += <<EOS
    <Variables/>
EOS
    end
    args_s = ""

    if args != nil
      args_s = args.join(", ")
    end

    template +=<<EOS
    <Code><![CDATA[#{@returnType} #{@name} (#{args_s}){
    $selected$$end$
}]]></Code>
  </CodeTemplate>
EOS
    template
  end
end

class ReSharper < Snippet
  @@var = "$name[i]$"

  class << self
    def to_text(snippets)

      text = <<EOS
<wpf:ResourceDictionary xml:space="preserve" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:s="clr-namespace:System;assembly=mscorlib" xmlns:ss="urn:shemas-jetbrains-com:settings-storage-xaml" xmlns:wpf="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
EOS
      text+= snippets.join("")
      text +=<<EOS
</wpf:ResourceDictionary>
EOS
    end
  end

  def to_s

    guid = SecureRandom.uuid.gsub("-", "").upcase
    template =<<EOS
<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Shortcut/@EntryValue">OnTriggerStay</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Description/@EntryValue">Message</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Reformat/@EntryValue">True</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/ShortenQualifiedReferences/@EntryValue">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Categories/=UnityC_0023/@EntryIndexedValue">UnityC#</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Applicability/=Live/@EntryIndexedValue">True</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Scope/=#{guid}/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Scope/=#{guid}/Type/@EntryValue">InCSharpFile</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Scope/=#{guid}/CustomProperties/=minimumLanguageVersion/@EntryIndexedValue">2.0</s:String>
EOS
    args = []
    @args.each_index { |i|
      template += <<EOS
<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Field/=name#{i}/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Field/=name#{i}/Expression/@EntryValue">constant("#{@args[i].name}")</s:String>
<s:Int64 x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Field/=name#{i}/Order/@EntryValue">0</s:Int64>
EOS
      args.push "#{@args[i].type} #{variable(i)}"

    }

    args_s = ""

    if args != nil
      args_s = args.join(", ")
    end

    template +=<<EOS
<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=#{guid}/Text/@EntryValue">#{@returnType} #{@name} (#{args_s}){
    $END$
}</s:String>
EOS

  end
end

class VSCode < Snippet

  @@var = "$name[i]$"

  class << self
    def to_text(snippets)
      text = <<EOS
'use strict';
define(["require", "exports"], function (require, exports) {
    exports.snippets = [
EOS
      snippets.join(",\n").split("\n").each { |s|
        text += "        #{s}\n"
      }
      text += <<EOS
    ];
});
EOS

    end
  end

  def to_s

    hash = {}
    hash['type'] = "snippet"
    hash['label'] = "#{@name}"
    hash['documentationLabel'] = "#{@name}"

    args = []
    @args.each_index { |i|
      args.push "#{@args[i].type} {{#{@args[i].type}}}"
    }

    args_s = ""

    if args != nil
      args_s = args.join(", ")
    end

    hash['codeSnippet'] = <<EOS
#{@returnType} #{@name} (#{args_s}){
    {{}}
}
EOS
    JSON.pretty_generate(hash)
  end
end

json = File.open('methods.json') { |f| JSON.load f }
methods = json['methods']


Monodevelop.write("Monodevelop/Unity.template.xml", methods)
ReSharper.write("ReSharper/UnityC#.DotSettings", methods)
VSCode.write("VSCode/snippets.js", methods)
