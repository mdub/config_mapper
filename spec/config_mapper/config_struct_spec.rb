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

  context "with an .attribute" do

    with_target_class do
      attribute :name
    end

    it "has accessor methods" do
      target.name = "bob"
      expect(target.name).to eql("bob")
    end

    context "declared with a block" do

      with_target_class do
        attribute(:size) { |arg| Integer(arg) }
      end

      it "invokes the block to validate the value" do
        expect { target.size = "abc" }.to raise_error(ArgumentError)
      end

      it "assigns the return value to the attribute" do
        target.size = "456"
        expect(target.size).to eql(456)
      end

    end

    context "that has a :default" do

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

    context "declared with a block and a default value" do

      with_target_class do
        attribute :port, :default => 5000, &method(:Integer)
      end

      context "and no override provided" do

        it "defaults to the specified value" do
          expect(target.port).to eql(5000)
        end

        it "invokes the block to validate the default value" do
          expect { target.port = "abc" }.to raise_error(ArgumentError)
        end

      end

      context "with overridden value" do

        it "assigns the return value to the attribute" do
          target.port = 456
          expect(target.port).to eql(456)
        end

        it "invokes the block to validate the override value" do
          expect { target.port = "abc" }.to raise_error(ArgumentError)
        end

      end

      context "with an optional value" do

        with_target_class do
          attribute :port, :default => nil, &method(:Integer)
        end

        it "assigns the return value to the attribute" do
          target.port = 456
          expect(target.port).to eql(456)
        end

        it "invokes the block to validate the override value" do
          expect { target.port = "abc" }.to raise_error(ArgumentError)
        end

        context "and an explicit nil value" do

          with_target_class do
            attribute :port, :default => nil, &method(:Integer)
          end

          it "assigns the return value to the attribute" do
            target.port = nil
            expect(target.port).to eql(nil)
          end

        end

      end

    end

  end

  context "with a .component" do

    context "declared with a block" do

      with_target_class do
        component :position do
          attribute :x
          attribute :y
        end
      end

      it "has a component with the specified name" do
        expect(target.position).to be_kind_of(ConfigMapper::ConfigStruct)
      end

      it "maintains component state" do
        target.position.x = 42
        expect(target.position.x).to eql(42)
      end

    end

    context "declared with a :type" do

      shirt_class = Struct.new(:colour, :size)

      with_target_class do
        component :shirt, :type => shirt_class
      end

      it "has a component of the specified type" do
        expect(target.shirt).to be_kind_of(shirt_class)
      end

    end

  end

  context "with a .component_dict" do

    describe "the named attribute" do

      with_target_class do
        component_dict :containers do
          attribute :image
        end
      end

      it "looks like a dictionary" do
        expect(target.containers).to respond_to(:[])
      end

      it "starts empty" do
        expect(target.containers).to be_empty
      end

      it "create entries on access" do
        target.containers["app"].image = "foo"
        expect(target.containers["app"].image).to eql("foo")
      end

      it "implements #keys" do
        target.containers["app"].image = "foo"
        expect(target.containers.keys).to eql(["app"])
      end

      it "can be enumerated" do
        target.containers["app"].image = "foo"
        container_images = {}
        target.containers.each do |name, container|
          container_images[name] = container.image
        end
        expect(container_images).to eql("app" => "foo")
      end

      it "can be configured" do
        config_data = {
          "containers" => {
            "app" => {
              "image" => "foobar"
            }
          }
        }
        errors = target.configure_with(config_data)
        expect(errors).to be_empty
        expect(target.containers["app"].image).to eql("foobar")
      end

    end

    context "declared with a :key_type" do

      with_target_class do
        component_dict :allow_access_on, :key_type => method(:Integer) do
          attribute :from
        end
      end

      it "invokes the key_type Proc to validate keys" do
        expect { target.allow_access_on["abc"] }.to raise_error
        expect { target.allow_access_on["22"] }.not_to raise_error
        expect(target.allow_access_on.keys).to eql([22])
      end

    end

  end

  describe "#config_errors" do

    with_target_class do
      attribute :foo
      attribute :bar
      attribute :baz, :default => nil
      component :position do
        attribute :x
      end
      component :shirt, :type => Struct.new(:x, :y)
      component_dict :services do
        attribute :port
      end
    end

    it "includes attributes that haven't been set" do
      expect(target.config_errors).to have_key(".foo")
    end

    it "includes component attributes that haven't been set" do
      expect(target.config_errors).to have_key(".position.x")
    end

    it "includes component_dict entry attributes that haven't been set" do
      target.services["app"]
      expect(target.config_errors).to have_key(%(.services["app"].port))
    end

    it "excludes attributes that have been set" do
      target.bar = "something"
      expect(target.config_errors).not_to have_key(".bar")
    end

    it "excludes attributes that have defaults" do
      expect(target.config_errors).not_to have_key(".baz")
    end

  end

  describe "#configure_with" do

    with_target_class do
      attribute(:shape)
      attribute(:size) { |arg| Integer(arg) }
      attribute(:name)
    end

    let!(:errors) do
      target.configure_with(:shape => "square", :size => "wobble")
    end

    it "sets attributes" do
      expect(target.shape).to eql("square")
    end

    it "returns marshalling errors" do
      expect(errors.keys).to include(".size")
      expect(errors[".size"]).to be_an(ArgumentError)
    end

    it "returns config_errors" do
      expect(errors.keys).to include(".name")
      expect(errors[".name"]).to eql("no value provided")
    end

  end

end
