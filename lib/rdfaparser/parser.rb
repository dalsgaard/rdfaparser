require 'nokogiri'
require 'rdfaparser/handler'

module RdfaParser

  class Parser
    
    def parse(doc, opts=nil, &block)
      handler = Handler.new opts, &block
      parser = Nokogiri::HTML::SAX::Parser.new handler
      parser.parse doc
    end

  end

  def self.parse(doc, opts=nil, &block)
    parser = Parser.new
    if block
      parser.parse doc, opts, &block
    else
      triples = []
      parser.parse doc, opts do |s, p, o|
        triples << [s, p, o]
      end
      triples
    end
  end

end
