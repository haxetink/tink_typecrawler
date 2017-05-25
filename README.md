# Tink Type Crawler

[![Build Status](https://travis-ci.org/haxetink/tink_typecrawler.svg?branch=master)](https://travis-ci.org/haxetink/tink_typecrawler)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxetink/public)

This library is for the crazy scientists. You have been warned.

The purpose of this library is to establish a common infrastructure upon which macro based data structure processors can be written, e.g. tink_json which uses compile time type information to generate parsers and serializers. Similarly, tink_xml and tink_serialize are good candidates.

There are neither tests nor documentation for this monstrosity, but if you like headaches, then reading tink_json is a good place to see this library in action. The basics are really simple: Call `tink.typecrawler.Crawler.crawl(type, pos, generator)` where `generator` must be a `tink.typecrawler.Generator` provided by the caller to determine how specific types are handled. The result is an array of fields and an entry point expression, so you want to either call this from a build macro or make a `TypeDefinition`.

The documentation of this library is likely to stay sparse for a moment, unless some one else shows interest in using it directly. So if you have such interest, by all means please show it ;)
