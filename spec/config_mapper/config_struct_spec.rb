require "config_mapper/config_struct"

describe ConfigMapper::ConfigStruct do

  let(:target) { target_class.new }

  describe ".property" do

    let(:target_class) do
      Class.new(ConfigMapper::ConfigStruct) do
        property :name
      end
    end

    it "defines accessor methods" do
      target.name = "bob"
      expect(target.name).to eql("bob")
    end

    context "with a block" do

      let(:target_class) do
        Class.new(ConfigMapper::ConfigStruct) do
          property(:size) { |arg| Integer(arg) }
        end
      end

      it "uses the block to check the value" do
        expect { target.size = "abc" }.to raise_error(ArgumentError)
      end

      it "assigns the return value to the attribute" do
        target.size = "456"
        expect(target.size).to eql(456)
      end

    end

  end

end
