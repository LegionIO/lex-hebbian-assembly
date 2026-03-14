# frozen_string_literal: true

module Legion
  module Extensions
    module HebbianAssembly
      module Runners
        module HebbianAssembly
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def activate_unit(id:, level: 1.0, domain: :general, **)
            Legion::Logging.debug "[hebbian] activate: id=#{id} level=#{level}"
            network.add_unit(id: id, domain: domain)
            unit = network.activate_unit(id: id, level: level)
            { success: true, unit: unit.to_h, assemblies: network.assembly_count }
          end

          def co_activate_units(ids:, level: 1.0, **)
            Legion::Logging.debug "[hebbian] co_activate: ids=#{ids}"
            results = network.co_activate(ids: ids, level: level)
            { success: true, units: results, assemblies: network.assembly_count }
          end

          def query_weight(from:, to:, **)
            w = network.query_weight(from: from, to: to)
            label = Helpers::Constants::WEIGHT_LABELS.each { |range, l| break l if range.cover?(w) }
            label = :nascent unless label.is_a?(Symbol)
            Legion::Logging.debug "[hebbian] weight: #{from}->#{to} = #{w}"
            { success: true, from: from, to: to, weight: w.round(4), label: label }
          end

          def list_assemblies(**)
            assemblies = network.assemblies.values.map(&:to_h)
            Legion::Logging.debug "[hebbian] list_assemblies: #{assemblies.size}"
            { success: true, assemblies: assemblies, count: assemblies.size }
          end

          def query_assembly(id:, **)
            asm = network.query_assembly(id: id.to_sym)
            Legion::Logging.debug "[hebbian] query_assembly: id=#{id} found=#{!asm.nil?}"
            if asm
              { success: true, assembly: asm.to_h }
            else
              { success: false, reason: :not_found }
            end
          end

          def pattern_complete(partial_ids:, **)
            Legion::Logging.debug "[hebbian] pattern_complete: partial=#{partial_ids}"
            result = network.pattern_complete(partial_ids: partial_ids)
            if result
              { success: true, completion: result }
            else
              { success: false, reason: :no_matching_assembly }
            end
          end

          def strongest_units(limit: 10, **)
            units = network.strongest_units(limit.to_i)
            Legion::Logging.debug "[hebbian] strongest_units: #{units.size}"
            { success: true, units: units }
          end

          def assemblies_for(unit_id:, **)
            asms = network.assemblies_containing(unit_id: unit_id).map(&:to_h)
            Legion::Logging.debug "[hebbian] assemblies_for: unit=#{unit_id} count=#{asms.size}"
            { success: true, assemblies: asms, count: asms.size }
          end

          def update_hebbian(**)
            Legion::Logging.debug '[hebbian] decay tick'
            network.decay_all
            { success: true, units: network.unit_count, assemblies: network.assembly_count }
          end

          def hebbian_stats(**)
            Legion::Logging.debug '[hebbian] stats'
            { success: true, stats: network.to_h }
          end

          private

          def network
            @network ||= Helpers::AssemblyNetwork.new
          end
        end
      end
    end
  end
end
