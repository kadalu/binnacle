# frozen_string_literal: true

require 'binnacle/store'
require 'binnacle/plugins'
require 'binnacle/plugins/commands'

module Binnacle
  module_function

  def run(task_file, debug: false)
    Store.set(:debug, debug)

    full_path = File.expand_path(task_file)

    begin
      load full_path
    rescue LoadError
      exit
    end
  end
end
