# ConfigMapper

[![Gem Version](https://badge.fury.io/rb/config_mapper.svg)](https://badge.fury.io/rb/config_mapper)
[![Build Status](https://travis-ci.org/mdub/config_mapper.svg?branch=master)](https://travis-ci.org/mdub/config_mapper)

ConfigMapper maps configuration data onto Ruby objects.

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Usage](#usage)
  - [Target object](#target-object)
  - [Errors](#errors)
- [ConfigStruct](#configstruct)
  - [Attributes](#attributes)
  - [Type validation/coercion](#type-validationcoercion)
  - [Defaults](#defaults)
  - [Semantic errors](#semantic-errors)
- [License](#license)
- [Contributing](#contributing)
- [See also](#see-also)

<!-- /TOC -->

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

errors = ConfigMapper.configure_with(config_data, state)
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

ConfigMapper.configure_with(config_data, positions)
positions["fred"].x            #=> 2
positions["mary"].y            #=> 5
```

### Target object

Given

```ruby
ConfigMapper.configure_with(config_data, target)
```

the `target` object is expected provide accessor-methods corresponding
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

`ConfigMapper.configure_with` returns a Hash of errors encountered while mapping data onto objects.  The errors are Exceptions (typically ArgumentError or NoMethodError), keyed by the path to the offending data.  e.g.

```ruby
config_data = {
  "position" => {
    "bogus" => "flibble"
  }
}

errors = ConfigMapper.configure_with(config_data, state)
errors    #=> { ".position.bogus" => #<NoMethodError> }
```

## ConfigStruct

ConfigMapper works pretty well with plain old Ruby objects, but we
provide a base-class, `ConfigMapper::ConfigStruct`, with a DSL that
makes it even easier to declare configuration data-structures.

### Attributes

The `attribute` method is similar to `attr_accessor`, defining both reader and writer methods for the named attribute.   

```ruby
require "config_mapper/config_struct"

class State < ConfigMapper::ConfigStruct

  attribute :orientation

end
```

### Type validation/coercion

If you specify a block when declaring an attribute, it will be invoked as part of the attribute's writer-method, to validate values when they are set. It should expect a single argument, and raise `ArgumentError` to signal invalid input. As the return value will be used as the value of the attribute, it's also an opportunity coerce values into canonical form.

```ruby
class Server < ConfigMapper::ConfigStruct

  attribute :host do |arg|
    unless arg =~ /^\w+(\.\w+)+$/
      raise ArgumentError, "invalid hostname: #{arg}"
    end
    arg
  end

  attribute :port do |arg|
    Integer(arg)
  end

end
```

Alternatively, specify a "validator" as a second argument to `attribute`.  It should be an object that responds to `#call`, with the same semantics described above. Good choices include `Proc` or `Method` objects, or type-objects from the [dry-types](http://dry-rb.org/gems/dry-types/) project.

```ruby
class Server < ConfigMapper::ConfigStruct

  attribute :host, Types::Strict::String.constrained(format: /^\w+(\.\w+)+$/)
  attribute :port, method(:Integer)

end
```

For convenience, primitive Ruby types such as `Integer` and `Float` can be used as shorthand for their namesake type-coercion methods on `Kernel`:

```ruby
class Server < ConfigMapper::ConfigStruct

  attribute :port, Integer

end
```

### Defaults

Attributes can be given default values, e.g.

```ruby
class Address < ConfigMapper::ConfigStruct
  attribute :host
  attribute :port, :default => 80
  attribute :path, :default => nil
end
```

Specify a default value of `nil` to mark an attribute as optional. Attributes without a default are treated as "required".

### Sub-components

The `component` method defines a nested component object, itself a `ConfigStruct`.  

```ruby
class State < ConfigMapper::ConfigStruct

  component :position do
    attribute :x
    attribute :y
  end

end
```

### Semantic errors

`ConfigStruct#config_errors` returns errors for each unset mandatory attribute.

```ruby
state = State.new
state.position.x = 3
state.position.y = 4
state.config_errors
#=> { ".orientation" => #<ConfigMapper::ConfigStruct::NoValueProvided: no value provided> }
```

`#config_errors` can be overridden to provide custom semantic validation.

`ConfigStruct#configure_with` maps data into the object, and combines mapping errors and semantic errors (returned by `#config_errors`) into a single Hash:

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
