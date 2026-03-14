# frozen_string_literal: true

module Legion
  module Extensions
    module HebbianAssembly
      module Helpers
        module Constants
          MAX_UNITS = 500
          MAX_ASSEMBLIES = 100
          MAX_CONNECTIONS_PER_UNIT = 30
          MAX_ACTIVATION_HISTORY = 200

          DEFAULT_WEIGHT = 0.1
          WEIGHT_FLOOR = 0.01
          MAX_WEIGHT = 1.0
          LEARNING_RATE = 0.05
          WEIGHT_DECAY = 0.002

          ACTIVATION_THRESHOLD = 0.3
          CO_ACTIVATION_WINDOW = 5
          ASSEMBLY_THRESHOLD = 3
          ASSEMBLY_MIN_WEIGHT = 0.3

          CONSOLIDATION_BOOST = 0.02
          COMPETITION_FACTOR = 0.01

          WEIGHT_LABELS = {
            (0.8..) => :bonded,
            (0.6...0.8) => :strong,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :weak,
            (..0.2) => :nascent
          }.freeze

          ASSEMBLY_STATE_LABELS = {
            active: 'assembly currently firing',
            primed: 'assembly recently active',
            dormant: 'assembly stable but inactive',
            forming: 'assembly still consolidating',
            dissolving: 'assembly losing coherence'
          }.freeze
        end
      end
    end
  end
end
