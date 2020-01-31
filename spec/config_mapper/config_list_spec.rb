# frozen_string_literal: true

require "config_mapper/config_list"

describe ConfigMapper::ConfigList do

  let(:entry_class) { Struct.new(:x, :y) }

  subject(:list) { ConfigMapper::ConfigList.new(entry_class) }

  it "looks like an array" do
    expect(list).to respond_to(:[])
  end

  it "starts empty" do
    expect(list).to be_empty
  end

  it "creates entries on access" do
    expect(list[0]).to_not be_nil
  end

  it "uses the entry_class to generate new values" do
    expect(list[0]).to be_kind_of(entry_class)
  end

  it "implements []" do
    list[0].x = 1
    expect(list[0].x).to eql(1)
  end

  it "can be enumerated" do
    list[0].x = 1
    x_values = []
    list.each_with_index do |item, index|
      x_values[index] = item.x
    end
    expect(x_values).to eql([1])
  end

end
