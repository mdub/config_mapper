require "bigdecimal"
require "config_mapper/config_struct"

module Testz

  class Book < ConfigMapper::ConfigStruct

    attribute :title
    attribute :author

  end

  class Library < ConfigMapper::ConfigStruct

    component_list :books, type: Book

  end

end

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

    it "declares accessor methods" do
      target.name = "bob"
      expect(target.name).to eql("bob")
    end

    context "with a block" do

      with_target_class do
        attribute :size do |arg|
          Integer(arg)
        end
      end

      it "uses the block to validate the value" do
        expect { target.size = "abc" }.to raise_error(ArgumentError)
      end

      it "assigns the block's return value to the attribute" do
        target.size = "456"
        expect(target.size).to eql(456)
      end

    end

    context "with a type" do

      case_insensitive_string = ->(arg) do
        if arg.respond_to?(:upcase)
          arg.upcase
        else
          raise ArgumentError, "not a String"
        end
      end

      with_target_class do
        attribute :name, case_insensitive_string
      end

      it "uses the block to validate the value" do
        expect { target.name = 22 }.to raise_error(ArgumentError)
      end

      it "assigns the block's return value to the attribute" do
        target.name = "Mike"
        expect(target.name).to eql("MIKE")
      end

    end

    context "with built-in type" do

      with_target_class do
        attribute :count, Integer
        attribute :length, Float
      end

      it "uses the corresonding coercion method" do

        target.count = "23"
        expect(target.count).to be(23)

        target.length = "23"
        expect(target.length).to be(23.0)

      end

    end

    context "with a :default" do

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

    context "when set to nil" do

      it "raises an ArgumentError" do
        expect { target.name = nil }.to raise_error(ArgumentError)
      end

    end

    context "optional" do

      with_target_class do
        attribute :port, :default => nil, &method(:Integer)
      end

      context "when set to nil" do

        it "bypasses the validation block" do
          target.port = nil
          expect(target.port).to be_nil
        end

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

    it "declares a sub-component" do
      expect(target.position).to be_kind_of(ConfigMapper::ConfigStruct)
    end

    it "maintains component state" do
      target.position.x = 42
      expect(target.position.x).to eql(42)
    end

    context "with a :type" do

      shirt_class = Struct.new(:colour, :size)

      with_target_class do
        component :shirt, :type => shirt_class
      end

      it "has a component of the specified type" do
        expect(target.shirt).to be_kind_of(shirt_class)
      end

    end

  end

  describe ".component_list" do

    with_target_class do
      component_list :books do
        attribute :title
        attribute :author
      end
    end

    it "declares a List-like component" do
      expect(target.books).to be_a(ConfigMapper::ConfigList)
    end

    it "defines an element-type" do
      expect(target.books[0]).to respond_to(:title)
    end

    it "can be configured" do
      config_data = {
          "books" => [
              {
                  "title" => "4321",
                  "author" => "Paul Auster"
              },
              {
                  "title" => "Sapiens : A Brief History of Humankind",
                  "author" => "Yuval Noah Harari"
              }
          ]
      }

      errors = target.configure_with(config_data)
      expect(errors).to be_empty
      expect(target.books.map { |b| b.title }).to eq(["4321", "Sapiens : A Brief History of Humankind"])
    end

    context "nested within a class" do

      let (:target_class) { Class.new(Testz::Library)}

      it "can be configured" do
        config_data = {
            "books" => [
                {
                    "title" => "4321",
                    "author" => "Paul Auster"
                },
                {
                    "title" => "Sapiens : A Brief History of Humankind",
                    "author" => "Yuval Noah Harari"
                }
            ]
        }

        errors = target.configure_with(config_data)
        expect(errors).to be_empty
        expect(target.books).to all(be_a(Testz::Book))
        expect(target.books.map { |b| b.title }).to eq(["4321", "Sapiens : A Brief History of Humankind"])
      end
    end
  end

  describe ".component_dict" do

    with_target_class do
      component_dict :containers do
        attribute :image
      end
    end

    it "declares a Hash-like component" do
      expect(target.containers).to be_a(ConfigMapper::ConfigDict)
    end

    it "defines an entry-type" do
      expect(target.containers["whatever"]).to respond_to(:image)
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

    context "with a :key_type" do

      with_target_class do
        component_dict :allow_access_on, :key_type => method(:Integer) do
          attribute :from
        end
      end

      it "invokes the key_type Proc to validate keys" do
        expect { target.allow_access_on["abc"] }.to raise_error(ArgumentError)
        expect { target.allow_access_on["22"] }.not_to raise_error
        expect(target.allow_access_on.keys).to eql([22])
      end

    end

  end

  describe ".config_doc" do

    with_target_class do
      attribute :flavour, description: "Chosen flavour"
      attribute :scoops, Integer, default: 2
      component :position, description: "Where it's at" do
        attribute :x, Float
        attribute :y, Float
      end
      component_dict :options do
        attribute :name
      end
    end

    let(:config_doc) { target_class.config_doc }

    it "returns data for each attribute" do
      expect(config_doc).to have_key(".flavour")
      expect(config_doc).to have_key(".scoops")
    end

    it "returns data for components" do
      expect(config_doc).to have_key(".position.x")
      expect(config_doc).to have_key(".position.y")
    end

    it "returns data for component_dicts" do
      expect(config_doc).to have_key(".options[X].name")
    end

    it "includes type information, where known" do
      expect(config_doc.dig(".flavour")).to_not include("type")
      expect(config_doc.dig(".scoops", "type")).to eql("Integer")
    end

    it "returns defaults, where specified" do
      expect(config_doc.dig(".flavour")).to_not include("default")
      expect(config_doc.dig(".scoops", "default")).to eql(2)
    end

    it "includes descriptions, where specified" do
      expect(config_doc.dig(".flavour", "description")).to eql("Chosen flavour")
      expect(config_doc.dig(".position", "description")).to eql("Where it's at")
      expect(config_doc.dig(".scoops")).to_not include("description")
    end

    it "sorts the keys" do
      doc_keys = config_doc.keys
      expect(doc_keys).to eql(doc_keys.sort)
    end

  end

  describe "#config_errors" do

    with_target_class do
      attribute :name
      attribute :port, :default => 80
      attribute :perhaps, :default => nil
      component :position do
        attribute :x
      end
      component :shirt, :type => Struct.new(:x, :y)
      component_dict :services do
        attribute :port
      end
    end

    it "includes unset attributes" do
      expect(target.config_errors).to have_key(".name")
    end

    it "excludes attributes set non-nil" do
      target.name = "something"
      expect(target.config_errors).not_to have_key(".name")
    end

    it "excludes optional attributes" do
      expect(target.config_errors).not_to have_key(".perhaps")
    end

    it "includes component attributes" do
      expect(target.config_errors).to have_key(".position.x")
    end

    it "includes component_dict entry attributes" do
      target.services["app"]
      expect(target.config_errors).to have_key(%(.services["app"].port))
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
      expect(errors[".name"].to_s).to eql("no value provided")
    end

  end

  describe ".from_data" do

    with_target_class do
      attribute(:shape)
      attribute(:size) { |arg| Integer(arg) }
    end

    def instantiate_from_data
      target_class.from_data(data)
    end

    context "with valid data" do

      let(:data) do
        {
          :shape => "square",
          :size => "3"
        }
      end

      let(:instance) { instantiate_from_data }

      it "sets attributes" do
        expect(instance.shape).to eql("square")
        expect(instance.size).to eql(3)
      end

    end

    context "with invalid data" do

      let(:data) do
        {
          :size => "free"
        }
      end

      it "raises an expection" do
        expect { instantiate_from_data }.to raise_error(ConfigMapper::MappingError)
      end

      let(:errors_by_field) do
        begin
          instantiate_from_data
        rescue ConfigMapper::MappingError => e
          e.errors_by_field
        end
      end

      it "returns marshalling errors" do
        expect(errors_by_field.keys).to include(".size")
        expect(errors_by_field[".size"]).to be_an(ArgumentError)
      end

      it "returns config_errors" do
        expect(errors_by_field.keys).to include(".shape")
        expect(errors_by_field[".shape"].to_s).to eql("no value provided")
      end

    end

  end

  describe "#to_h" do

    with_target_class do
      attribute :name
      attribute :port, :default => 80
      component :position do
        attribute :x
        attribute :y
      end
      component_dict :services do
        attribute :port
      end
      component_list :aliases do
        attribute :alias
      end
      attribute :words
    end

    it "includes attribute values" do
      target.name = "Jim"
      expect(target.to_h).to include("name" => "Jim")
    end

    it "includes defaults" do
      expect(target.to_h).to include("port" => 80)
    end

    it "includes components" do
      target.position.x = 123
      expected = {
        "position" => {
          "x" => 123,
          "y" => nil
        }
      }
      expect(target.to_h).to include(expected)
    end

    it "includes component_dicts" do
      target.services["foo"].port = 5678
      expected = {
        "services" => {
          "foo" => {
            "port" => 5678
          }
        }
      }
      expect(target.to_h).to include(expected)
    end

    it "includes component_lists" do
      target.aliases[0].alias = "fred"
      target.aliases[1].alias = "jane"
      expected = {
        "aliases" => [
          {
            "alias" => "fred"
          },
          {
            "alias" => "jane"
          }
        ]
      }
      expect(target.to_h).to include(expected)
    end

    it "does sensible things with arrays" do
      target.words = ["blah"]
      expected = {
        "words" => ["blah"]
      }
      expect(target.to_h).to include(expected)
    end

  end

  describe "sub-class" do

    let(:super_class) do
      Class.new(ConfigMapper::ConfigStruct) do

        attribute :name

        attribute :port, :default => 5000

        component :position do
          attribute :x
          attribute :y
        end

        component_dict :containers do
          attribute :image
        end

      end
    end

    let(:sub_class) do
      Class.new(super_class) do
        attribute :description
      end
    end

    let(:target) { sub_class.new }

    it "inherits attributes from super-class" do
      expect(target.config_errors.keys).to include(".name")
      target.name = "bob"
      expect(target.name).to eql("bob")
    end

    it "inherits defaults" do
      expect(target.port).to eql(5000)
    end

    it "inherits components from super-class" do
      expect(target.position).to be_kind_of(ConfigMapper::ConfigStruct)
      expect(target.config_errors.keys).to include(".position.x")
    end

    it "inherits component_dicts from super-class" do
      expect(target.containers).to be_kind_of(ConfigMapper::ConfigDict)
    end

  end

end
