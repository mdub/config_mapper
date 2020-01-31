# frozen_string_literal: true

module ConfigMapper

  # Thrown to indicate a problem parsing config.
  #
  class MappingError < StandardError

    def initialize(errors_by_field)
      @errors_by_field = errors_by_field
      super(generate_message)
    end

    attr_reader :errors_by_field

    private

    def generate_message
      result = "configuration error"
      errors_by_field.each do |field, error|
        result += "\n  #{field[1..-1]} - #{error}"
      end
      result
    end

  end

end
