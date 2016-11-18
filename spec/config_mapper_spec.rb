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

    def each(&block)
      @positions_by_name.each(&block)
    end

  end

  class Thing

    attr_accessor :foo
    attr_accessor :bar

  end

end

describe ConfigMapper, ".configure_with" do

  let!(:errors) { described_class.configure_with(source_data, target) }

  context "targeting a simple object" do

    let(:position) { Testy::Position.new }
    let(:target) { position }

    context "with a simple hash" do

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

    context "with an array" do

      let(:source_data) do
        %w(a b c)
      end

      it "records NoMethodErrors for array indices" do
        expect(errors[".0"]).to be_a(NoMethodError)
        expect(errors[".2"]).to be_a(NoMethodError)
      end

    end

    context "with complex data" do

      let(:thing) { Testy::Thing.new }
      let(:target) { thing }

      let(:source_data) do
        {
          "foo" => { "x" => 1, "y" => 2 },
          "bar" => ["a", "b", "c"]
        }
      end

      it "just sets the attributes" do
        expect(thing.foo).to eql("x" => 1, "y" => 2)
        expect(thing.bar).to eql(["a", "b", "c"])
      end

      it "records no errors" do
        expect(errors).to be_empty
      end

    end

  end

  context "targeting a complex object" do

    let(:state) { Testy::State.new }
    let(:target) { state }

    context "with nested hashes" do

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

  context "targeting a read-only collection" do

    let(:positions) { Testy::NamedPositions.new }
    let(:target) { positions }

    context "with nested hashes" do

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

    context "with an array" do

      let(:source_data) do
        [
          { "x" => 3, "y" => 4 },
          { "x" => 5, "y" => 6, "attitude" => "unknown" }
        ]
      end

      it "uses array index as a key" do
        expect(positions[0].x).to eq(3)
        expect(positions[0].y).to eq(4)
      end

      it "records errors raised by nested objects" do
        bad_attitude = "[1].attitude"
        expect(errors.keys).to include(bad_attitude)
        expect(errors[bad_attitude]).to be_a(NoMethodError)
      end

    end

  end

end
