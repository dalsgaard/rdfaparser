$:.unshift 'lib'
require 'rdfaparser/node.rb'

include RdfaParser

describe Node do

  it "should support a cascading lang" do
    parent = Node.new ["xml:lang", "da"]
    parent.lang.should == "da"
    child = Node.new [], parent
    child.lang.should == "da"
    child = Node.new ["xml:lang", "en"], parent
    child.lang.should == "en"    
  end

  it "should support a cascading default namespace" do
    parent = Node.new ["xmlns", "http://foo.bar#"]
    parent.default_namespace.should == "http://foo.bar#"
    child = Node.new [], parent
    child.default_namespace.should == "http://foo.bar#"
    child = Node.new ["xmlns", "http://bar.baz#"], parent
    child.default_namespace.should == "http://bar.baz#"    
  end

  it "should support cascading namespaces" do
    parent = Node.new ["xmlns:bar", "http://foo.bar#"]
    parent.namespace("bar").should == "http://foo.bar#"
    child = Node.new [], parent
    child.namespace("bar").should == "http://foo.bar#"
    child = Node.new ["xmlns:bar", "http://bar.baz#"], parent
    child.namespace("bar").should == "http://bar.baz#"    
  end

  it "should support cascading about" do
    parent = Node.new ["about", "http://foo.bar#baz"]
    parent.about.should == ["http://foo.bar#baz"]
    child = Node.new [], parent
    child.about.should == ["http://foo.bar#baz"]
    child = Node.new ["about", "http://bar.baz#foo"], parent
    child.about.should == ["http://bar.baz#foo"]        
  end

  it "should have an initial base of nil" do
    Root.new.base.should be_nil
  end

  it "should support initial setting of base" do
    root = Root.new :base => "http://foo.bar"
    root.base.should == "http://foo.bar"
  end

  it "should support a base attribute" do
    root = Root.new
    parent = Node.new [], root
    child = Node.new ["base", "http://foo.bar"], parent
    root.base.should == "http://foo.bar"
  end

  it "should support a subject defaulting to base" do
    root = Root.new :base => "http://foo.bar"
    parent = Node.new [], root
    child = Node.new [], parent
    child.subject.should == ["http://foo.bar"]
  end

  it "should support a subject taking the value of about when present" do
    root = Root.new
    parent = Node.new ["about", "http://foo.bar"], root
    child = Node.new [], parent
    child.subject.should == ["http://foo.bar"]
  end

  it "should default subject to empty when no base" do
    node = Node.new
    node.subject.should eql([])
  end

  it "should resolve a safe curie blank node" do
    node = Node.new
    node.uri_or_safe_curie("[_:foo]").should == :foo
  end

  it "should resolve a safe curie node" do
    node = Node.new ["xmlns:foo", "http://foo.bar#"]
    node.uri_or_safe_curie("[foo:baz]").should == ["http://foo.bar#baz"]
  end

  it "should resolve a subject uri" do
    node = Node.new
    uri = "http://foo.bar#baz"
    node.uri_or_safe_curie(uri).should == [uri]
  end

  it "should resolve a relative subject uri" do
    base = "http://foo.bar"
    rel = "#baz"
    root = Root.new :base => base
    parent = Node.new [], root
    child = Node.new [], parent
    child.uri_or_safe_curie(rel).should == [base + rel]    
  end

  it "should resolve a relative subject uri without a base" do
    rel = "#baz"
    parent = Node.new []
    child = Node.new [], parent
    child.uri_or_safe_curie(rel).should == [rel]    
  end

  it "should resolve a curie" do
    node = Node.new ["xmlns:foo", "http://foo.bar#"]
    node.curie("foo:baz").should == ["http://foo.bar#baz"]
  end

  it "should map blank nodes with same naming convensions" do
    node = Node.new
    b0 = node.root.blank.next_node
    b1 = node.root.blank.next_node
    b = node.uri_or_safe_curie "[_:b1x]"
    b.should be_a(Symbol)
    b.should_not eql(b1)
    b.should eql(node.uri_or_safe_curie("[_:b1x]"))
  end

  it "should support typeof" do
    t = []
    attrs = ["xmlns:foo", "http://foo.bar#",
             "about", "[foo:baz]",
             "typeof", "foo:Baz"]
    node = Node.new attrs do |s, p, o|
      t << [s, p, o]
    end
    t.should eql([[["http://foo.bar#baz"],
                   ["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"],
                   ["http://foo.bar#Baz"]]])
  end

  it "should support typeof creating a blank node" do
    attrs = ["xmlns:foo", "http://foo.bar#", "typeof", "foo:Baz"]
    node = Node.new attrs do
    end
    node.about.should be_a(Symbol)
  end

  it "should support rel and resource" do
    subject = "http://foo.bar"
    object = "http://bar.baz"
    triples = []
    parent = Node.new ["about", subject, "xmlns:foo", "http://foo.bar#"]
    attrs = ["rel", "foo:baz", "resource", object]
    child = Node.new attrs, parent do |s, p, o|
      triples << [s, p, o]
    end
    triples.should eql([[[subject], ["http://foo.bar#baz"], [object]]])
  end

  it "should support property and content" do
    triples = []
    parent = Node.new ["xmlns:foo", "http://foo.bar#"]
    attrs = ["property", "foo:baz", "content", "Bar"]
    child = Node.new attrs, parent do |s, p, o|
      triples << [s, p, o]
    end
    triples.should eql([[[], ["http://foo.bar#baz"], "Bar"]])
  end

  it "should support property and inline" do
    triples = []
    parent = Node.new ["xmlns:foo", "http://foo.bar#"]
    attrs = ["property", "foo:baz"]
    child = Node.new attrs, parent do |s, p, o|
      triples << [s, p, o]
    end
    child.inline "Bar"
    triples.should eql([[[], ["http://foo.bar#baz"], "Bar"]])
  end

  it "should support empty inline" do
    triples = []
    node = Node.new ["xmlns:foo", "http://foo.bar#",
                     "property", "foo:baz"] do |s, p, o|
      triples << [s, p, o]
    end
    node.inline ""
    triples.should eql([[[], ["http://foo.bar#baz"], ""]])
  end

  it "should support datatype" do
    triples = []
    parent = Node.new ["xmlns:foo", "http://foo.bar#"]
    attrs = ["property", "foo:baz", "content", "Bar", "datatype", "foo:int"]
    child = Node.new attrs, parent do |s, p, o|
      triples << [s, p, o]
    end
    triples.should eql([[[],
                         ["http://foo.bar#baz"],
                         ["Bar", ["http://foo.bar#int"]]]])    
  end

  it "should support incomplete triples" do
    triples = []
    top = Node.new ["xmlns:foo", "http://foo.bar#",
                     "rel", "foo:baz"] do |s, p, o|
      triples << [s, p, o]
    end
    middle = Node.new [], top
    bottom = Node.new ["about", "http://foo.baz"], middle
    triples.should eql([[[], ["http://foo.bar#baz"], ["http://foo.baz"]]])  
  end

end
