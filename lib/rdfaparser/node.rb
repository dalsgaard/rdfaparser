
module RdfaParser

  TypeOf = ["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]

  class BlankNodeGenerator
    
    def initialize()
      @index = 0
      @map = {}
    end

    def next_node()
      blank = "b#{@index}x".to_sym
      @index += 1
      blank
    end

    def map(s)
      if blank = @map[s]
        blank
      else
        @map[s] = next_node()
      end
    end

  end

  class Root

    def initialize(opts=nil)
      if opts
        @base = opts[:base]
      end
      @namespaces = {}
      @blank = BlankNodeGenerator.new
    end

    def root()
      self
    end

    def blank()
      @blank
    end

    def complete(about)
    end

    def lang()
      @lang
    end

    def default_namespace()
      @default_namespace
    end

    def namespace(prefix)
      @namespaces[prefix]
    end

    def subject()
      @base ? [@base] : []
    end

    def about()
      []
    end

    def base(uri=nil)
      if uri
        @base = uri
      else
        @base
      end
    end

  end

  class Node
    attr_reader :parent

    def initialize(attrs=nil, parent=nil, &block)
      @parent = parent || Root.new
      @namespaces = {}
      @block = block
      apply attrs, &block if attrs
    end

    def apply(attrs)
      props = {}
      until attrs.empty?
        key = attrs.shift
        value = attrs.shift
        case key
        when "xml:lang"
          @lang = value
        when "xmlns"
          @default_namespace = value
        when /^xmlns:(.+)/
          @namespaces[$1] = value
        when "base"
          base value
        when "about"
          props[:about] = value
        when "rel"
          props[:rel] = value          
        when "rev"
          props[:rev] = value
        when "property"
          props[:property] = value
        when "resource"
          props[:resource] = value
        when "href"
          props[:href] = value
        when "content"
          @content = value
        when "src"
          props[:src] = value
        when "typeof"
          props[:typeof] = value
        when "datatype"
          props[:datatype] = value
        end
      end
      if props[:about]
        @about = uri_or_safe_curie props[:about]
      else
        @about = root.blank.next_node if props[:typeof]
      end
      if props[:typeof]
        typeof = curie props[:typeof]
        yield subject, TypeOf, typeof
      end
      @rel = curie props[:rel] if props[:rel]
      if @resource = props[:resource]
        if @rel
          yield subject, @rel, uri_or_safe_curie(@resource)
        end
      end
      @datatype = curie props[:datatype] if props[:datatype]
      if props[:property]
        @property = curie props[:property]
        if @content
          @content = [@content, @datatype] if @datatype
          yield subject, @property, @content
        end
      end
      @parent.complete @about if @about
    end

    def inline(text)
      if @property and not @content
        text = [text, @datatype] if @datatype
        @block.call subject, @property, text        
      end
    end

    def root()
      @root ||= @parent.root
    end

    def complete(about)
      if @rel and not @resource
        @block.call subject, @rel, about        
      else
        @parent.complete about unless @about
      end
    end

    def lang()
      @lang ||= (@parent ? @parent.lang : nil)
    end

    def default_namespace()
      @default_namespace ||= @parent.default_namespace
    end

    def namespace(prefix)
      @namespaces[prefix] ||= @parent.namespace(prefix)
    end

    def about()
      @about ||= @parent.about
    end

    def subject()
      @subject ||= @about || @parent.subject
    end

    def base(uri=nil)
      if uri
        @parent.base (@uri = uri)
      else
        @base ||= @parent.base
      end
    end

    def uri_or_safe_curie(s)
      case s
      when /^\[_:b(\d+)x\]$/
        root.blank.map s
      when /^\[_:(.+)\]$/
        $1.to_sym
      when /^\[([^:]+):([^:]+)\]$/
        [namespace($1) + $2]
      when /^http:\/\//
        [s]
      else
        ["#{base}#{s}"]
      end
    end

    def curie(s)
      s =~ /^([^:]+):([^:]+)$/
      [namespace($1) + $2]
    end

  end

end
