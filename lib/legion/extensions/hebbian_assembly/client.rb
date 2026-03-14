# frozen_string_literal: true

require 'legion/extensions/hebbian_assembly/helpers/constants'
require 'legion/extensions/hebbian_assembly/helpers/unit'
require 'legion/extensions/hebbian_assembly/helpers/assembly'
require 'legion/extensions/hebbian_assembly/helpers/assembly_network'
require 'legion/extensions/hebbian_assembly/runners/hebbian_assembly'

module Legion
  module Extensions
    module HebbianAssembly
      class Client
        include Runners::HebbianAssembly

        def initialize(network: nil, **)
          @network = network || Helpers::AssemblyNetwork.new
        end

        private

        attr_reader :network
      end
    end
  end
end
