# frozen_string_literal: true

# Module with the collection of binnacle keywords
# and helper utilities
module Binnacle
  module Utils
    module_function

    def caller_line_number
      loc = caller_locations[1]
      "#{loc.path}:#{loc.lineno}"
    end

    def response(data)
      flag = Store.get(:response)

      if flag == 'return'
        return data
      elsif flag == 'stdout'
        puts "#{data.to_json}\n\n"
      else
        warn "#{data.to_json}\n\n"
      end

      exit 1 if Store.get(:exit_on_not_ok) && !data[:ok]

      # If output key exists in the response then
      # return it. It may be used by the caller.
      # Like: `data = run "cat ~/report.csv"`
      data.key?(:output) ? data[:output] : nil
    end
  end
end
