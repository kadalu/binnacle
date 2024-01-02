# frozen_string_literal: true

module Kadalu
  module Binnacle
    # Validate if the given two values are equal
    #
    # ```
    # compare_equal? 10, 10, "Test Title"
    # ```
    #
    # ```
    # compare_equal? var1, 100, "Value is 100"
    # ```
    register_plugin 'compare_equal?' do |value1, value2, title = ''|
      ok = value1 == value2
      unless ok
        puts <<-MSG
        Value1:
        --
        #{value1}
        --

        Value2:
        --
        #{value2}
        --
        MSG
      end

      {
        value1: value1,
        value2: value2,
        ok: ok,
        title: title
      }
    end

    # For backward compatibility
    register_plugin 'EQUAL' do |value1, value2, title = ''|
      data = {}
      Store.set(:response, 'return') do
        data = Plugins.compare_equal?(value1, value2, title)
      end

      data
    end

    # Validate if the given two values are equal
    #
    # ```
    # compare_not_equal? 11, 10, "Test Title"
    # ```
    #
    # ```
    # compare_not_equal? var1, 100, "Value is 100"
    # ```
    register_plugin 'compare_not_equal?' do |value1, value2, title = ''|
      ok = value1 != value2
      unless ok
        puts <<-MSG
        Value1 and Value2 are same
        --
        #{value1}
        --
        MSG
      end

      {
        value1: value1,
        value2: value2,
        ok: ok,
        title: title
      }
    end

    # For backward compatibility
    register_plugin 'NOT_EQUAL' do |value1, value2, title = ''|
      data = {}
      Store.set(:response, 'return') do
        data = Plugins.compare_not_equal?(value1, value2, title)
      end

      data
    end

    # Validate if the given statement is true
    #
    # ```
    # compare_true? var1 == 10, "Test Title"
    # ```
    register_plugin 'compare_true?' do |expr, title = ''|
      {
        ok: expr == true,
        title: title
      }
    end

    # For backward compatibility
    register_plugin 'TRUE' do |expr, title = ''|
      data = {}
      Store.set(:response, 'return') do
        data = Plugins.compare_true?(expr, title)
      end

      data
    end

    # Validate if the given statement is false
    #
    # ```
    # compare_false? var1 == 10, "Test Title"
    # ```
    register_plugin 'compare_false?' do |expr, title = ''|
      {
        ok: expr == false,
        title: title
      }
    end

    # For backward compatibility
    register_plugin 'FALSE' do |expr, title = ''|
      data = {}
      Store.set(:response, 'return') do
        data = Plugins.compare_false?(expr, title)
      end

      data
    end
  end
end
