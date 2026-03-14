# frozen_string_literal: true

require 'legion/extensions/hebbian_assembly/version'
require 'legion/extensions/hebbian_assembly/helpers/constants'
require 'legion/extensions/hebbian_assembly/helpers/unit'
require 'legion/extensions/hebbian_assembly/helpers/assembly'
require 'legion/extensions/hebbian_assembly/helpers/assembly_network'
require 'legion/extensions/hebbian_assembly/runners/hebbian_assembly'
require 'legion/extensions/hebbian_assembly/client'

module Legion
  module Extensions
    module HebbianAssembly
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
