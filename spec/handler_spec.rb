$:.unshift 'lib'
require 'rdfaparser/node.rb'

include RdfaParser

describe Handler do

  before :each do
    @handler = Handler.new
  end

  it "should handle lang attributes" do
    
  end

end

