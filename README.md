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

errors = ConfigMapper.set(config_data, state)
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

ConfigMapper.set(config_data, positions)
positions["fred"].x            #=> 2
positions["mary"].y            #=> 5
```

### Target object

Given

```ruby
ConfigMapper.set(config_data, config_target)
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

`ConfigMapper.set` returns a Hash of errors encountered while mapping data
onto objects.  The errors are Exceptions (typically ArgumentError or NoMethodError),
keyed by a Array representing the path to the offending data.  e.g.

```ruby
config_data = {
  "position" => {
    "bogus" => "flibble"
  }
}

errors = ConfigMapper.set(config_data, state)
errors    #=> { ["position", "bogus"] => #<NoMethodError> }
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contributing

It's on GitHub; you know the drill.

## See also

* [ConfigHound](https://github.com/mdub/config_hound) is a great way to
  load raw config-data, before throwing it to ConfigMapper.
