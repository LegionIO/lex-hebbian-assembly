# frozen_string_literal: true

module Legion
  module Extensions
    module HebbianAssembly
      module Helpers
        class Assembly
          include Constants

          attr_reader :id, :member_ids, :formed_at, :activation_count, :last_activated
          attr_accessor :coherence

          def initialize(id:, member_ids:)
            @id               = id
            @member_ids       = Array(member_ids).uniq
            @coherence        = 0.5
            @formed_at        = Time.now.utc
            @activation_count = 0
            @last_activated   = nil
          end

          def activate
            @activation_count += 1
            @last_activated = Time.now.utc
          end

          def consolidate
            @coherence = [@coherence + CONSOLIDATION_BOOST, MAX_WEIGHT].min
          end

          def decay
            @coherence = [@coherence - WEIGHT_DECAY, 0.0].max
          end

          def dissolving?
            @coherence < ASSEMBLY_MIN_WEIGHT
          end

          def member_count
            @member_ids.size
          end

          def includes?(unit_id)
            @member_ids.include?(unit_id)
          end

          def state
            if @last_activated && (Time.now.utc - @last_activated) < CO_ACTIVATION_WINDOW
              :active
            elsif @last_activated && (Time.now.utc - @last_activated) < (CO_ACTIVATION_WINDOW * 3)
              :primed
            elsif dissolving?
              :dissolving
            elsif @coherence >= ASSEMBLY_MIN_WEIGHT
              :dormant
            else
              :forming
            end
          end

          def to_h
            {
              id: @id,
              members: @member_ids.dup,
              member_count: member_count,
              coherence: @coherence.round(4),
              state: state,
              state_label: ASSEMBLY_STATE_LABELS[state],
              activation_count: @activation_count,
              formed_at: @formed_at,
              last_activated: @last_activated
            }
          end
        end
      end
    end
  end
end
