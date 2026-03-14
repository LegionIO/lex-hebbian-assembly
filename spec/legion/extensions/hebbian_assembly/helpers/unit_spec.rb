# frozen_string_literal: true

RSpec.describe Legion::Extensions::HebbianAssembly::Helpers::Unit do
  subject(:unit) { described_class.new(id: :neuron_a, domain: :cognition) }

  let(:constants) { Legion::Extensions::HebbianAssembly::Helpers::Constants }

  describe '#initialize' do
    it 'sets attributes' do
      expect(unit.id).to eq(:neuron_a)
      expect(unit.domain).to eq(:cognition)
      expect(unit.activation_level).to eq(0.0)
      expect(unit.activation_count).to eq(0)
    end
  end

  describe '#activate' do
    it 'sets activation level and increments count' do
      unit.activate(level: 0.8)
      expect(unit.activation_level).to eq(0.8)
      expect(unit.activation_count).to eq(1)
      expect(unit.last_activated).to be_a(Time)
    end

    it 'clamps activation' do
      unit.activate(level: 1.5)
      expect(unit.activation_level).to eq(1.0)
    end
  end

  describe '#active?' do
    it 'returns true when above threshold' do
      unit.activate(level: 0.5)
      expect(unit.active?).to be true
    end

    it 'returns false when below threshold' do
      expect(unit.active?).to be false
    end
  end

  describe '#connect' do
    it 'creates a connection' do
      unit.connect(:neuron_b, weight: 0.3)
      expect(unit.weight_to(:neuron_b)).to eq(0.3)
    end

    it 'clamps weight' do
      unit.connect(:neuron_b, weight: 2.0)
      expect(unit.weight_to(:neuron_b)).to eq(1.0)
    end

    it 'limits connections' do
      constants::MAX_CONNECTIONS_PER_UNIT.times { |i| unit.connect(:"n_#{i}") }
      unit.connect(:overflow)
      expect(unit.connection_count).to eq(constants::MAX_CONNECTIONS_PER_UNIT)
    end
  end

  describe '#strengthen' do
    it 'increases weight' do
      unit.connect(:neuron_b, weight: 0.3)
      unit.strengthen(:neuron_b)
      expect(unit.weight_to(:neuron_b)).to eq(0.3 + constants::LEARNING_RATE)
    end

    it 'caps at MAX_WEIGHT' do
      unit.connect(:neuron_b, weight: 0.98)
      unit.strengthen(:neuron_b)
      expect(unit.weight_to(:neuron_b)).to eq(constants::MAX_WEIGHT)
    end
  end

  describe '#weaken' do
    it 'decreases weight' do
      unit.connect(:neuron_b, weight: 0.5)
      unit.weaken(:neuron_b)
      expect(unit.weight_to(:neuron_b)).to eq(0.5 - constants::COMPETITION_FACTOR)
    end
  end

  describe '#decay_weights' do
    it 'decays all connections' do
      unit.connect(:neuron_b, weight: 0.5)
      unit.decay_weights
      expect(unit.weight_to(:neuron_b)).to eq(0.5 - constants::WEIGHT_DECAY)
    end

    it 'prunes connections at floor' do
      unit.connect(:neuron_b, weight: constants::WEIGHT_FLOOR + 0.001)
      unit.decay_weights
      expect(unit.connection_count).to eq(0)
    end
  end

  describe '#weight_label' do
    it 'returns label for weight' do
      unit.connect(:neuron_b, weight: 0.9)
      expect(unit.weight_label(:neuron_b)).to eq(:bonded)
    end
  end

  describe '#strongest_connections' do
    it 'returns top connections sorted by weight' do
      unit.connect(:a, weight: 0.3)
      unit.connect(:b, weight: 0.8)
      unit.connect(:c, weight: 0.5)
      top = unit.strongest_connections(2)
      expect(top.keys).to eq(%i[b c])
    end
  end

  describe '#to_h' do
    it 'returns hash' do
      h = unit.to_h
      expect(h).to include(:id, :domain, :activation_level, :active, :connections, :activation_count)
    end
  end
end
