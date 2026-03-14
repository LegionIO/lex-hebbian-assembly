# frozen_string_literal: true

RSpec.describe Legion::Extensions::HebbianAssembly::Helpers::AssemblyNetwork do
  subject(:network) { described_class.new }

  let(:constants) { Legion::Extensions::HebbianAssembly::Helpers::Constants }

  describe '#add_unit' do
    it 'adds a unit' do
      unit = network.add_unit(id: :a)
      expect(unit.id).to eq(:a)
      expect(network.unit_count).to eq(1)
    end

    it 'returns existing unit on duplicate' do
      first = network.add_unit(id: :a)
      second = network.add_unit(id: :a)
      expect(first).to equal(second)
    end

    it 'limits units' do
      constants::MAX_UNITS.times { |i| network.add_unit(id: :"u_#{i}") }
      expect(network.add_unit(id: :overflow)).to be_nil
    end
  end

  describe '#activate_unit' do
    it 'activates a unit' do
      unit = network.activate_unit(id: :a, level: 0.8)
      expect(unit.activation_level).to eq(0.8)
      expect(unit.active?).to be true
    end

    it 'auto-creates unit if missing' do
      network.activate_unit(id: :new_unit)
      expect(network.unit_count).to eq(1)
    end

    it 'records activation history' do
      network.activate_unit(id: :a)
      expect(network.activation_history.size).to eq(1)
    end
  end

  describe '#co_activate' do
    it 'activates multiple units' do
      results = network.co_activate(ids: %i[a b c])
      expect(results.size).to eq(3)
      expect(network.unit_count).to eq(3)
    end

    it 'strengthens connections between co-activated units' do
      network.co_activate(ids: %i[a b])
      expect(network.query_weight(from: :a, to: :b)).to be > 0
      expect(network.query_weight(from: :b, to: :a)).to be > 0
    end

    it 'repeated co-activation increases weight' do
      network.co_activate(ids: %i[a b])
      first_weight = network.query_weight(from: :a, to: :b)
      network.co_activate(ids: %i[a b])
      expect(network.query_weight(from: :a, to: :b)).to be > first_weight
    end
  end

  describe '#query_weight' do
    it 'returns 0 for unconnected units' do
      expect(network.query_weight(from: :a, to: :b)).to eq(0.0)
    end
  end

  describe 'assembly detection' do
    it 'forms assembly from repeated co-activation of 3+ units' do
      10.times { network.co_activate(ids: %i[a b c], level: 1.0) }
      expect(network.assembly_count).to be >= 1
    end

    it 'consolidates existing assembly on repeated co-activation' do
      10.times { network.co_activate(ids: %i[a b c], level: 1.0) }
      assembly = network.assemblies.values.first
      first_coherence = assembly.coherence
      5.times { network.co_activate(ids: %i[a b c], level: 1.0) }
      expect(assembly.coherence).to be >= first_coherence
    end
  end

  describe '#assemblies_containing' do
    it 'finds assemblies containing a unit' do
      10.times { network.co_activate(ids: %i[a b c], level: 1.0) }
      asms = network.assemblies_containing(unit_id: :a)
      expect(asms).not_to be_empty
      expect(asms.first.includes?(:a)).to be true
    end
  end

  describe '#pattern_complete' do
    it 'completes partial pattern from assembly' do
      10.times { network.co_activate(ids: %i[a b c], level: 1.0) }
      result = network.pattern_complete(partial_ids: %i[a b])
      expect(result).not_to be_nil
      expect(result[:predicted]).to include(:c)
    end

    it 'returns nil when no matching assembly' do
      expect(network.pattern_complete(partial_ids: [:unknown])).to be_nil
    end
  end

  describe '#strongest_units' do
    it 'returns most activated units' do
      5.times { network.activate_unit(id: :frequent, level: 1.0) }
      network.activate_unit(id: :rare, level: 1.0)
      top = network.strongest_units(1)
      expect(top.first[:id]).to eq(:frequent)
    end
  end

  describe '#decay_all' do
    it 'decays unit weights' do
      network.co_activate(ids: %i[a b])
      before = network.query_weight(from: :a, to: :b)
      network.decay_all
      expect(network.query_weight(from: :a, to: :b)).to be < before
    end

    it 'removes dissolving assemblies' do
      10.times { network.co_activate(ids: %i[a b c], level: 1.0) }
      network.assemblies.each_value { |a| a.coherence = 0.1 }
      network.decay_all
      expect(network.assembly_count).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns stats' do
      network.co_activate(ids: %i[a b c])
      h = network.to_h
      expect(h).to include(:units, :assemblies, :total_connections, :history_size, :active_units)
      expect(h[:units]).to eq(3)
    end
  end
end
