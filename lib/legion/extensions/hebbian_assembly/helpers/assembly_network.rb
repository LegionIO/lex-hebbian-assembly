# frozen_string_literal: true

module Legion
  module Extensions
    module HebbianAssembly
      module Helpers
        class AssemblyNetwork
          include Constants

          attr_reader :units, :assemblies, :activation_history

          def initialize
            @units              = {}
            @assemblies         = {}
            @activation_history = []
            @assembly_counter   = 0
          end

          def add_unit(id:, domain: :general)
            return @units[id] if @units.key?(id)
            return nil if @units.size >= MAX_UNITS

            @units[id] = Unit.new(id: id, domain: domain)
          end

          def activate_unit(id:, level: 1.0)
            ensure_unit(id)
            unit = @units[id]
            unit.activate(level: level)
            record_activation(id)
            hebbian_update(id)
            detect_assemblies
            unit
          end

          def co_activate(ids:, level: 1.0)
            ids = Array(ids)
            ids.each do |id|
              ensure_unit(id)
              @units[id].activate(level: level)
              record_activation(id)
            end

            ids.combination(2).each do |a, b|
              ensure_connection(a, b)
              @units[a].strengthen(b)
              @units[b].strengthen(a)
            end

            detect_assemblies
            ids.map { |id| @units[id].to_h }
          end

          def query_weight(from:, to:)
            return 0.0 unless @units.key?(from)

            @units[from].weight_to(to)
          end

          def query_assembly(id:)
            @assemblies[id]
          end

          def assemblies_containing(unit_id:)
            @assemblies.values.select { |a| a.includes?(unit_id) }
          end

          def pattern_complete(partial_ids:)
            partial = Array(partial_ids)
            candidates = partial.flat_map { |uid| assemblies_containing(unit_id: uid) }.uniq(&:id)
            return nil if candidates.empty?

            best = candidates.max_by { |a| (partial & a.member_ids).size }
            missing = best.member_ids - partial
            { assembly_id: best.id, known: partial & best.member_ids, predicted: missing, coherence: best.coherence }
          end

          def strongest_units(n = 10)
            @units.values
                  .sort_by { |u| -u.activation_count }
                  .first(n)
                  .map(&:to_h)
          end

          def decay_all
            @units.each_value(&:decay_weights)
            @assemblies.each_value(&:decay)
            @assemblies.reject! { |_, a| a.dissolving? }
          end

          def unit_count
            @units.size
          end

          def assembly_count
            @assemblies.size
          end

          def to_h
            {
              units: @units.size,
              assemblies: @assemblies.size,
              total_connections: @units.values.sum(&:connection_count),
              history_size: @activation_history.size,
              active_units: @units.values.count(&:active?)
            }
          end

          private

          def ensure_unit(id)
            add_unit(id: id) unless @units.key?(id)
          end

          def ensure_connection(a, b)
            @units[a].connect(b) unless @units[a].connections.key?(b)
            @units[b].connect(a) unless @units[b].connections.key?(a)
          end

          def record_activation(id)
            @activation_history << { unit_id: id, at: Time.now.utc }
            @activation_history.shift while @activation_history.size > MAX_ACTIVATION_HISTORY
          end

          def hebbian_update(active_id)
            recent_window = Time.now.utc - CO_ACTIVATION_WINDOW
            recent_ids = @activation_history
                         .select { |h| h[:at] >= recent_window && h[:unit_id] != active_id }
                         .map { |h| h[:unit_id] }
                         .uniq

            recent_ids.each do |other_id|
              next unless @units.key?(other_id) && @units[other_id].active?

              ensure_connection(active_id, other_id)
              @units[active_id].strengthen(other_id)
              @units[other_id].strengthen(active_id)
            end
          end

          def detect_assemblies
            strongly_connected = find_strongly_connected
            return if strongly_connected.size < ASSEMBLY_THRESHOLD

            existing = find_matching_assembly(strongly_connected)
            existing ? reinforce_assembly(existing) : create_assembly(strongly_connected)
          end

          def find_strongly_connected
            active_ids = @units.values.select(&:active?).map(&:id)
            return [] if active_ids.size < ASSEMBLY_THRESHOLD

            active_ids.select do |uid|
              peers = active_ids - [uid]
              peers.count { |p| @units[uid].weight_to(p) >= ASSEMBLY_MIN_WEIGHT } >= (ASSEMBLY_THRESHOLD - 1)
            end
          end

          def find_matching_assembly(member_ids)
            @assemblies.values.find do |a|
              (member_ids - a.member_ids).empty? && (a.member_ids - member_ids).empty?
            end
          end

          def reinforce_assembly(assembly)
            assembly.activate
            assembly.consolidate
          end

          def create_assembly(member_ids)
            @assembly_counter += 1
            id = :"assembly_#{@assembly_counter}"
            @assemblies[id] = Assembly.new(id: id, member_ids: member_ids)
            @assemblies[id].activate
            prune_assemblies if @assemblies.size > MAX_ASSEMBLIES
          end

          def prune_assemblies
            weakest = @assemblies.min_by { |_, a| a.coherence }&.first
            @assemblies.delete(weakest) if weakest
          end
        end
      end
    end
  end
end
