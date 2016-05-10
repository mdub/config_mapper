require "config_mapper"

module Testy

  class Position

    attr_reader :x
    attr_reader :y

    def x=(arg)
      @x = Integer(arg)
    end

    def y=(arg)
      @y = Integer(arg)
    end

  end

  class State

    def initialize
      @position ||= Position.new
    end

    attr_reader :position
    attr_accessor :orientation

  end

  class NamedPositions

    def initialize
      @positions_by_name = {}
    end

    def [](name)
      @positions_by_name[name] ||= Position.new
    end

    def key?(name)
      @positions_by_name.key?(name)
    end

  end

  class ThingWithSubnets

    attr_accessor :subnets

  end

  class ThingWithAHash

    def initialize
      @stuff = { "foo" => "bar" }
    end

    attr_accessor :stuff

  end

end

describe ConfigMapper do

  describe ".configure_with" do

    let!(:errors) { described_class.configure_with(source_data, target) }

    context "with a simple Hash" do

      let(:position) { Testy::Position.new }
      let(:target) { position }

      let(:source_data) do
        {
          "x" => 1,
          "y" => "juan",
          "z" => 42
        }
      end

      it "sets recognised attributes" do
        expect(position.x).to eql(1)
      end

      it "records ArgumentErrors raised by setter-methods" do
        expect(errors[".y"]).to be_a(ArgumentError)
      end

      it "records NoMethodErrors for unrecognised keys" do
        expect(errors[".z"]).to be_a(NoMethodError)
      end

    end

    context "with a nested Hash" do

      context "if there is a writer method" do

        let(:thing) { Testy::ThingWithAHash.new }
        let(:target) { thing }

        let(:source_data) do
          {
            "stuff" => {
              "x" => 1,
              "y" => 2
            }
          }
        end

        it "overwrites the Hash" do
          expect(thing.stuff).to eql("x" => 1, "y" => 2)
        end

        it "records no errors" do
          expect(errors).to be_empty
        end

      end

      context "otherwise" do

        let(:state) { Testy::State.new }
        let(:target) { state }

        let(:source_data) do
          {
            "position" => {
              "x" => 1,
              "y" => "juan"
            }
          }
        end

        it "sets recognised attributes" do
          expect(state.position.x).to eql(1)
        end

        it "records errors raised by nested objects" do
          expect(errors[".position.y"]).to be_a(ArgumentError)
        end

      end

    end

    context "with an Array of values" do

      let(:thing) { Testy::ThingWithSubnets.new }
      let(:target) { thing }

      let(:source_data) do
        {
          :subnets => [
            "subnet-1",
            "subnet-2"
          ]
        }
      end

      it "sets the Array value" do
        expect(thing.subnets).to eql(%w(subnet-1 subnet-2))
      end

    end

    context "when the target is a read-only collection" do

      let(:positions) { Testy::NamedPositions.new }
      let(:target) { positions }

      let(:source_data) do
        {
          "stan" => { "x" => 1, "y" => 2 },
          "mary" => { "x" => 5, "y" => 6, "attitude" => "unknown" }
        }
      end

      it "maps onto the object found" do
        expect(positions["stan"].x).to eq(1)
      end

      it "records errors raised by nested objects" do
        bad_attitude = '["mary"].attitude'
        expect(errors.keys).to include(bad_attitude)
        expect(errors[bad_attitude]).to be_a(NoMethodError)
      end

    end

  end

end
