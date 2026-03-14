# frozen_string_literal: true

module Legion
  module Extensions
    module HebbianAssembly
      module Helpers
        class Unit
          include Constants

          attr_reader :id, :domain, :connections, :activation_count, :last_activated
          attr_accessor :activation_level

          def initialize(id:, domain: :general)
            @id               = id
            @domain           = domain
            @activation_level = 0.0
            @connections      = {}
            @activation_count = 0
            @last_activated   = nil
          end

          def activate(level: 1.0)
            @activation_level = level.to_f.clamp(0.0, 1.0)
            @activation_count += 1
            @last_activated = Time.now.utc
          end

          def active?
            @activation_level >= ACTIVATION_THRESHOLD
          end

          def connect(other_id, weight: DEFAULT_WEIGHT)
            return if @connections.size >= MAX_CONNECTIONS_PER_UNIT && !@connections.key?(other_id)

            @connections[other_id] = weight.to_f.clamp(WEIGHT_FLOOR, MAX_WEIGHT)
          end

          def strengthen(other_id, amount: LEARNING_RATE)
            return unless @connections.key?(other_id)

            @connections[other_id] = [@connections[other_id] + amount, MAX_WEIGHT].min
          end

          def weaken(other_id, amount: COMPETITION_FACTOR)
            return unless @connections.key?(other_id)

            @connections[other_id] = [@connections[other_id] - amount, WEIGHT_FLOOR].max
          end

          def weight_to(other_id)
            @connections[other_id] || 0.0
          end

          def weight_label(other_id)
            w = weight_to(other_id)
            WEIGHT_LABELS.each { |range, lbl| return lbl if range.cover?(w) }
            :nascent
          end

          def decay_weights
            @connections.each do |k, w|
              @connections[k] = [w - WEIGHT_DECAY, WEIGHT_FLOOR].max
            end
            @connections.reject! { |_, w| w <= WEIGHT_FLOOR }
          end

          def connection_count
            @connections.size
          end

          def strongest_connections(n = 5)
            @connections.sort_by { |_, w| -w }.first(n).to_h
          end

          def to_h
            {
              id: @id,
              domain: @domain,
              activation_level: @activation_level.round(4),
              active: active?,
              connections: @connections.size,
              activation_count: @activation_count,
              last_activated: @last_activated
            }
          end
        end
      end
    end
  end
end
