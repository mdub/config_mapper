# ConfigMapper

ConfigMapper maps configuration data onto Ruby objects.

## Usage

Imagine you have some Ruby objects:

```ruby
class Position

  attr_reader :x
  attr_reader :y

  def x=(arg); @x = Integer(arg); end
  def y=(arg); @y = Integer(arg); end

end

class State

  def initialize
    @position = Position.new
  end

  attr_reader :position
  attr_accessor :orientation

end

state = State.new
```

and wish to populate/modify it, based on plain data:

```ruby
config_data = {
  "orientation" => "North",
  "position" => {
    "x" => 2,
    "y" => 4
  }
}
```

ConfigMapper will help you out:

```ruby
require 'config_mapper'

errors = ConfigMapper.configure(state).with(config_data)
state.orientation              #=> "North"
state.position.x               #=> 2
```

It can even populate Hashes of objects, e.g.

```ruby
positions = Hash.new { |h,k| h[k] = Position.new }

config_data = {
  "fred" => { "x" => 2, "y" => 4 },
  "mary" => { "x" => 3, "y" => 5 }
}

ConfigMapper.configure(positions).with(config_data)
positions["fred"].x            #=> 2
positions["mary"].y            #=> 5
```

### Target object

Given

```ruby
ConfigMapper.configure(config_target).with(config_data)
```

the `config_target` object is expected provide accessor-methods corresponding
to the attributes that you want to make configurable.  For example, with:

```ruby
config_data = {
  "orientation" => "North",
  "position" => { "x" => 2, "y" => 4 }
}
```

it should have a `orientiation=` method, and a `position` method that
returns a `Position` object, which should in turn have `x=` and `y=`
methods.

ConfigMapper cannot and will not _create_ objects for you.

### Errors

`ConfigMapper.set` returns a Hash of errors encountered while mapping data onto objects.  The errors are Exceptions (typically ArgumentError or NoMethodError), keyed by the path to the offending data.  e.g.

```ruby
config_data = {
  "position" => {
    "bogus" => "flibble"
  }
}

errors = ConfigMapper.configure(state).with(config_data)
errors    #=> { ".position.bogus" => #<NoMethodError> }
```

## ConfigStruct

ConfigMapper works pretty well with plain old Ruby objects, but we
provide a base-class, `ConfigMapper::ConfigStruct`, with a DSL that
makes it even easier to declare configuration data-structures.

```ruby
require "config_mapper/config_struct"

class State < ConfigMapper::ConfigStruct

  component :position do
    attribute(:x) { |arg| Integer(arg) }
    attribute(:y) { |arg| Integer(arg) }
  end

  attribute :orientation

end
```

By default, declared attributes are assumed to be mandatory. The
`ConfigStruct#config_errors` method returns errors for each unset mandatory
attribute.

```ruby
state = State.new
state.position.x = 3
state.position.y = 4
state.config_errors
#=> { ".orientation" => "no value provided" }
```

`#config_errors` can be overridden to provide custom semantic validation.

Attributes can be given default values. Provide an explicit `nil` default to
mark an attribute as optional, e.g.

```ruby
class Address < ConfigMapper::ConfigStruct

  attribute :host
  attribute :port, :default => 80
  attribute :path, :default => nil

end
```

`ConfigStruct#configure_with` maps data into the object, and combines mapping errors and
semantic errors (returned by `#config_errors`) into a single Hash:

```ruby
data = {
  "position" => { "x" => 3, "y" => "fore" },
  "bogus" => "foobar"
}
state.configure_with(data)
#=> {
#=>   ".orientation" => "no value provided",
#=>   ".position.y" => #<ArgumentError: invalid value for Integer(): "fore">,
#=>   ".bogus" => #<NoMethodError: undefined method `bogus=' for #<State:0x007fc8e9b12a60>>
#=> }
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contributing

It's on GitHub; you know the drill.

## See also

* [ConfigHound](https://github.com/mdub/config_hound) is a great way to
  load raw config-data, before throwing it to ConfigMapper.
