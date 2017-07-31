require "config_mapper/config_dict"

describe ConfigMapper::ConfigDict do

  let(:entry_class) { Struct.new(:x, :y) }

  subject(:key_type) { nil }

  subject(:dict) { ConfigMapper::ConfigDict.new(entry_class, key_type) }

  it "looks like a dictionary" do
    expect(dict).to respond_to(:[])
  end

  it "starts empty" do
    expect(dict).to be_empty
  end

  it "creates entries on access" do
    expect(dict["foo"]).to_not be_nil
  end

  it "uses the entry_class to generate new values" do
    expect(dict["foo"]).to be_kind_of(entry_class)
  end

  it "implements #keys" do
    dict["foo"]
    expect(dict.keys).to eql(["foo"])
  end

  it "can be enumerated" do
    dict["foo"].x = 1
    x_values = {}
    dict.each do |name, entry|
      x_values[name] = entry.x
    end
    expect(x_values).to eql("foo" => 1)
  end

  context "declared with a :key_type" do

    let(:key_type) do
      lambda { |arg| arg.to_s.upcase }
    end

    it "invokes the key_type Proc to coerce and validate keys" do
      dict["foo"].x = 123
      expect(dict["FOO"].x).to eql(123)
      expect(dict.keys).to eql(["FOO"])
    end

  end

end
