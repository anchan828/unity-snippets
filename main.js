/**
 * Created by keigo on 2016/01/01.
 */
'use strict';

let fs = require('fs');
let uuid = require('node-uuid');
class Snippet {

    constructor(method) {

        this.isStatic = method.isStatic;
        this.namespace = method.namespace;
        this.name = method.name;
        this.returnType = method.returnType;
        this.args = [];

        if (method.args) {
            this.args = method.args.map((arg, index)=> {
                arg['index'] = index;
                return arg
            })
        }
    }

    static write(path, methods) {
        let snippets = methods.map((method)=> {
            return new this(method);
        });

        let text = this.toText(snippets)

        fs.writeFileSync(path, text)
    }

    static toText() {

    }
}


class Monodevelop extends Snippet {

    static toText(snippets) {
        let text = []
        text.push(`<?xml version="1.0" encoding="utf-8"?>`)
        text.push(`<CodeTemplates version="3.0">`)
        text.push(snippets.join("") + `</CodeTemplates>`);
        return text.join(`\n`);
    }

    toString() {

        let template = []
        template.push(`    <CodeTemplate version="2.0">`)
        template.push(`        <Header>`)
        template.push(`            <_Group>UnityC#</_Group>`)
        template.push(`            <MimeType>text/x-csharp</MimeType>`)
        template.push(`            <Version>1.0</Version>`)
        template.push(`            <_Description>Message</_Description>`)
        template.push(`            <TemplateType>SurroundsWith,Expansion</TemplateType>`)
        template.push(`            <Shortcut>${this.name}</Shortcut>`)
        template.push(`        </Header>`);

        let mArgs = [];
        if (this.args.length != 0) {
            template.push(`        <Variables>`);
            mArgs = this.args.map((arg, i)=> {
                template.push(`            <Variable name="name${i}">`)
                template.push(`                <Default>${this.args[i].name}</Default>`)
                template.push(`            </Variable>`)
                return `${this.args[i].type} $name${i}$`
            });
            template.push(`        </Variables>`)

        } else {
            template.push(`        <Variables/>`)
        }
        let args_s = mArgs.join(", ");

        template.push(`        <Code><![CDATA[${this.returnType} ${this.name} (${args_s}){`)
        template.push(`$selected$$end$`)
        template.push(`}]]></Code>`)
        template.push(`    </CodeTemplate>`)
        template.push(``)
        return template.join(`\n`)
    }
}

class ReSharper extends Snippet {

    static toText(snippets) {
        let text = []
        text.push(`<wpf:ResourceDictionary xml:space="preserve" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:s="clr-namespace:System;assembly=mscorlib" xmlns:ss="urn:shemas-jetbrains-com:settings-storage-xaml" xmlns:wpf="http://schemas.microsoft.com/winfx/2006/xaml/presentation">`)
        text.push(snippets.join(""))
        text.push(`</wpf:ResourceDictionary>`)
        return text.join(`\n`);
    }

    toString() {
        let text = []
        let guid = uuid.v4().replace(/-/g, "").toUpperCase()
        text.push(`<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/@KeyIndexDefined">True</s:Boolean>`)
        text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Shortcut/@EntryValue">${this.name}</s:String>`)
        text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Description/@EntryValue">Message</s:String>`)
        text.push(`<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Reformat/@EntryValue">True</s:Boolean>`)
        text.push(`<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/ShortenQualifiedReferences/@EntryValue">True</s:Boolean>`)
        text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Categories/=UnityC_0023/@EntryIndexedValue">UnityC#</s:String>`)
        text.push(`<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Applicability/=Live/@EntryIndexedValue">True</s:Boolean>`)
        text.push(`<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Scope/=${guid}/@KeyIndexDefined">True</s:Boolean>`)
        text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Scope/=${guid}/Type/@EntryValue">InCSharpFile</s:String>`)
        text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Scope/=${guid}/CustomProperties/=minimumLanguageVersion/@EntryIndexedValue">2.0</s:String>`)

        let args_s = this.args.map((arg, i)=> {
            text.push(`<s:Boolean x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Field/=name${i}/@KeyIndexDefined">True</s:Boolean>`)
            text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Field/=name${i}/Expression/@EntryValue">constant("${arg.name}")</s:String>`)
            text.push(`<s:Int64 x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Field/=name${i}/Order/@EntryValue">0</s:Int64>`)
            return `${arg.type} $name${i}$`
        }).join(", ")

        text.push(`<s:String x:Key="/Default/PatternsAndTemplates/LiveTemplates/Template/=${guid}/Text/@EntryValue">${this.returnType} ${this.name} (${args_s}){`)
        text.push(`    $END$`)
        text.push(`}</s:String>`)
        text.push(``)

        return text.join(`\n`)
    }
}

class VSCode extends Snippet {

    static toText(snippets) {

        let json = JSON.parse(`{\n${snippets.join(",\n")}\n}`)
        return JSON.stringify(json, null, 2)
    }

    toString() {
        let json = {
            prefix: this.name,
            body: [],
            description: ""
        }

        let args_s = this.args.map((arg)=> {
            return `${arg.type} \${${arg.name}}`
        }).join(", ")

        json.body.push(`${this.returnType} ${this.name} (${args_s}){`);
        json.body.push(`    $0`)
        json.body.push(`}`)

        return `"${this.name}":${JSON.stringify(json)}`
    }
}

let json = fs.readFileSync('./methods.json');
let methods = JSON.parse(json).methods;
Monodevelop.write("Monodevelop/Unity.template.xml", methods);
ReSharper.write("ReSharper/UnityC#.DotSettings", methods);
VSCode.write("VSCode/csharp.json", methods);
