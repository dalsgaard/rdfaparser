require 'nokogiri'
require 'rdfaparser/node'

module RdfaParser

  class Handler < Nokogiri::XML::SAX::Document

    def initialize(opts=nil, &block)
      @block = block
      @node = Root.new opts
      @inline = nil
    end

    def push(attrs)
      @node = Node.new attrs, @node, &@block
    end

    def pop()
      @node = @node.parent
    end

    def start_element(name, attrs = [])
      push attrs
      @inline = ""
    end

    def characters(s)
      @inline << s
    end

    def end_element(name)
      @node.inline @inline
      pop
    end

  end

end
