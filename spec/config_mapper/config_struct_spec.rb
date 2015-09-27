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

    context "with a block" do

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

    context "with a component Class" do

      shirt_class = Struct.new(:colour, :size)

      with_target_class do
        component :shirt, shirt_class
      end

      it "initializes the component with an instance of that class" do
        expect(target.shirt).to be_kind_of(shirt_class)
      end

    end

  end

  describe ".component_map" do

    with_target_class do
      component_map :containers do
        attribute :image
      end
    end

    it "defines a map" do
      expect(target.containers).to respond_to(:[])
    end

    it "starts empty" do
      expect(target.containers).to be_empty
    end

    it "create entries on access" do
      target.containers["app"].image = "foo"
      expect(target.containers["app"].image).to eql("foo")
    end

  end

  describe "#undefined_attributes" do

    with_target_class do
      attribute :foo
      attribute :bar
      attribute :baz, :default => nil
      component :position do
        attribute :x
      end
      component :shirt, Struct.new(:x, :y)
      component_map :services do
        attribute :port
      end
    end

    it "includes attributes that haven't been set" do
      expect(target.undefined_attributes).to include("foo")
    end

    it "includes component attributes that haven't been set" do
      expect(target.undefined_attributes).to include("position.x")
    end

    it "includes component-map entry attributes that haven't been set" do
      target.services["app"]
      expect(target.undefined_attributes).to include(%(services["app"].port))
    end

    it "excludes attributes that have been set" do
      target.bar = "something"
      expect(target.undefined_attributes).not_to include("bar")
    end

    it "excludes attributes that have defaults" do
      expect(target.undefined_attributes).not_to include("baz")
    end

  end

end
