# frozen_string_literal: true

RSpec.describe Legion::Extensions::HebbianAssembly::Runners::HebbianAssembly do
  let(:client) { Legion::Extensions::HebbianAssembly::Client.new }

  describe '#activate_unit' do
    it 'activates a unit' do
      result = client.activate_unit(id: :a, level: 0.8, domain: :cognition)
      expect(result[:success]).to be true
      expect(result[:unit][:id]).to eq(:a)
      expect(result[:unit][:active]).to be true
    end
  end

  describe '#co_activate_units' do
    it 'co-activates multiple units' do
      result = client.co_activate_units(ids: %i[a b c])
      expect(result[:success]).to be true
      expect(result[:units].size).to eq(3)
    end
  end

  describe '#query_weight' do
    it 'returns weight between units' do
      client.co_activate_units(ids: %i[a b])
      result = client.query_weight(from: :a, to: :b)
      expect(result[:success]).to be true
      expect(result[:weight]).to be > 0
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns 0 for unconnected' do
      result = client.query_weight(from: :x, to: :y)
      expect(result[:weight]).to eq(0.0)
    end
  end

  describe '#list_assemblies' do
    it 'lists assemblies' do
      10.times { client.co_activate_units(ids: %i[a b c]) }
      result = client.list_assemblies
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end
  end

  describe '#query_assembly' do
    it 'queries a specific assembly' do
      10.times { client.co_activate_units(ids: %i[a b c]) }
      all = client.list_assemblies
      id = all[:assemblies].first[:id]
      result = client.query_assembly(id: id)
      expect(result[:success]).to be true
      expect(result[:assembly][:members]).to include(:a, :b, :c)
    end

    it 'returns not_found for unknown' do
      result = client.query_assembly(id: :nonexistent)
      expect(result[:success]).to be false
    end
  end

  describe '#pattern_complete' do
    it 'completes partial pattern' do
      10.times { client.co_activate_units(ids: %i[a b c]) }
      result = client.pattern_complete(partial_ids: %i[a b])
      expect(result[:success]).to be true
      expect(result[:completion][:predicted]).to include(:c)
    end

    it 'returns failure when no match' do
      result = client.pattern_complete(partial_ids: [:unknown])
      expect(result[:success]).to be false
    end
  end

  describe '#strongest_units' do
    it 'returns most activated units' do
      5.times { client.activate_unit(id: :freq) }
      client.activate_unit(id: :rare)
      result = client.strongest_units(limit: 1)
      expect(result[:units].first[:id]).to eq(:freq)
    end
  end

  describe '#assemblies_for' do
    it 'finds assemblies for a unit' do
      10.times { client.co_activate_units(ids: %i[a b c]) }
      result = client.assemblies_for(unit_id: :a)
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end
  end

  describe '#update_hebbian' do
    it 'runs decay tick' do
      result = client.update_hebbian
      expect(result[:success]).to be true
    end
  end

  describe '#hebbian_stats' do
    it 'returns stats' do
      result = client.hebbian_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:units, :assemblies, :total_connections)
    end
  end
end
