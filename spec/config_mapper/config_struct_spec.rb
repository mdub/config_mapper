require "config_mapper/config_struct"

describe ConfigMapper::ConfigStruct do

  def self.with_target_class(&block)
    let(:target_class) do
      Class.new(ConfigMapper::ConfigStruct) do
        class_eval(&block)
      end
    end
  end

  let(:target) { target_class.new }

  describe ".attribute" do

    with_target_class do
      attribute :name
    end

    it "defines accessor methods" do
      target.name = "bob"
      expect(target.name).to eql("bob")
    end

    context "with a block" do

      with_target_class do
        attribute(:size) { |arg| Integer(arg) }
      end

      it "uses the block to check the value" do
        expect { target.size = "abc" }.to raise_error(ArgumentError)
      end

      it "assigns the return value to the attribute" do
        target.size = "456"
        expect(target.size).to eql(456)
      end

    end

    context "with a Symbol argument" do

      with_target_class do
        attribute :size, :Integer
      end

      it "invokes the corresponding type-coercion method" do
        expect { target.size = "abc" }.to raise_error(ArgumentError)
      end

      it "assigns the return value to the attribute" do
        target.size = "456"
        expect(target.size).to eql(456)
      end

    end

    context "with a default" do

      with_target_class do
        attribute :port, :default => 5000
      end

      it "defaults to the specified value" do
        expect(target.port).to eql(5000)
      end

      it "allows override of default" do
        target.port = 456
        expect(target.port).to eql(456)
      end

    end

  end

  describe ".component" do

    with_target_class do
      component :position do
        attribute :x
        attribute :y
      end
    end

    it "creates a sub-structure" do
      expect(target.position).to be_kind_of(ConfigMapper::ConfigStruct)
    end

    it "maintains component state" do
      target.position.x = 42
      expect(target.position.x).to eql(42)
    end

  end

  describe "#unset_attributes" do

    with_target_class do
      attribute :foo
      attribute :bar
      attribute :baz, :default => nil
      component :position do
        attribute :x
      end
    end

    it "includes attributes that haven't been set" do
      expect(target.unset_attributes).to include("foo")
    end

    it "includes component attributes that haven't been set" do
      expect(target.unset_attributes).to include("position.x")
    end

    it "excludes attributes that have been set" do
      target.bar = "something"
      expect(target.unset_attributes).not_to include("bar")
    end

    it "excludes attributes that have defaults" do
      expect(target.unset_attributes).not_to include("baz")
    end

  end

end
