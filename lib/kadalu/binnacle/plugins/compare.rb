# frozen_string_literal: true

module Kadalu::Binnacle
  # Validate if the given two values are equal
  #
  # ```
  # equal? 10, 10, "Test Title"
  # ```
  #
  # ```
  # equal? var1, 100, "Value is 100"
  # ```
  register_plugin 'equal?' do |value1, value2, title = ''|
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
      data = Plugins.equal?(value1, value2, title)
    end

    data
  end

  # Validate if the given two values are equal
  #
  # ```
  # not_equal? 11, 10, "Test Title"
  # ```
  #
  # ```
  # not_equal? var1, 100, "Value is 100"
  # ```
  register_plugin 'not_equal?' do |value1, value2, title = ''|
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
      data = Plugins.not_equal?(value1, value2, title)
    end

    data
  end

  # Validate if the given statement is true
  #
  # ```
  # true? var1 == 10, "Test Title"
  # ```
  register_plugin 'true?' do |expr, title = ''|
    {
      ok: expr == true,
      title: title
    }
  end

  # For backward compatibility
  register_plugin 'TRUE' do |expr, title = ''|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.true?(expr, title)
    end

    data
  end

  # Validate if the given statement is false
  #
  # ```
  # false? var1 == 10, "Test Title"
  # ```
  register_plugin 'false?' do |expr, title = ''|
    {
      ok: expr == false,
      title: title
    }
  end

  # For backward compatibility
  register_plugin 'FALSE' do |expr, title = ''|
    data = {}
    Store.set(:response, 'return') do
      data = Plugins.false?(expr, title)
    end

    data
  end
end
