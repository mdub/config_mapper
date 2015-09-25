require "config_mapper/config_struct"

describe ConfigMapper::ConfigStruct do

  class MyConfig < ConfigMapper::ConfigStruct

    property :name

  end

  context "with a single property" do

    let(:target) { MyConfig.new }

    it "has accessor methods for the property" do
      target.name = "bob"
      expect(target.name).to eql("bob")
    end

  end

end
