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

end

describe ConfigMapper do

  let(:target) { Testy::Position.new }

  subject(:mapper) { described_class.new(target) }

  describe ".set" do

    let!(:errors) { described_class.set(source_hash, target) }

    context "with a simple Hash" do

      let(:source_hash) do
        {
          "x" => 1,
          "y" => "juan",
          "z" => 42
        }
      end

      it "sets recognised attributes" do
        expect(target.x).to eql(1)
      end

      it "records ArgumentErrors raised by setter-methods" do
        expect(errors["y"]).to be_a(ArgumentError)
      end

      it "records NoMethodErrors for unrecognised keys" do
        expect(errors["z"]).to be_a(NoMethodError)
      end

    end

    context "with a nested Hash" do

      let(:target) { Testy::State.new }

      let(:source_hash) do
        {
          "position" => {
            "x" => 1,
            "y" => "juan"
          },
          "inclination" => "vertical"
        }
      end

      it "sets recognised attributes" do
        expect(target.position.x).to eql(1)
      end

      it "records errors raised by nested objects" do
        expect(errors["position.y"]).to be_a(ArgumentError)
      end

      it "records errors for unrecognised keys" do
        expect(errors["inclination"]).to be_a(NoMethodError)
      end

    end

  end

end
