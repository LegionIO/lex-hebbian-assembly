# frozen_string_literal: true

RSpec.describe Legion::Extensions::HebbianAssembly::Helpers::Assembly do
  subject(:assembly) { described_class.new(id: :asm_one, member_ids: %i[a b c]) }

  let(:constants) { Legion::Extensions::HebbianAssembly::Helpers::Constants }

  describe '#initialize' do
    it 'sets attributes' do
      expect(assembly.id).to eq(:asm_one)
      expect(assembly.member_ids).to eq(%i[a b c])
      expect(assembly.coherence).to eq(0.5)
    end

    it 'deduplicates members' do
      asm = described_class.new(id: :dup, member_ids: %i[a a b])
      expect(asm.member_ids).to eq(%i[a b])
    end
  end

  describe '#activate' do
    it 'increments activation count' do
      assembly.activate
      expect(assembly.activation_count).to eq(1)
      expect(assembly.last_activated).to be_a(Time)
    end
  end

  describe '#consolidate' do
    it 'increases coherence' do
      before = assembly.coherence
      assembly.consolidate
      expect(assembly.coherence).to be > before
    end
  end

  describe '#decay' do
    it 'decreases coherence' do
      before = assembly.coherence
      assembly.decay
      expect(assembly.coherence).to be < before
    end
  end

  describe '#dissolving?' do
    it 'returns false when coherent' do
      expect(assembly.dissolving?).to be false
    end

    it 'returns true when coherence drops below threshold' do
      assembly.coherence = 0.1
      expect(assembly.dissolving?).to be true
    end
  end

  describe '#includes?' do
    it 'returns true for members' do
      expect(assembly.includes?(:a)).to be true
    end

    it 'returns false for non-members' do
      expect(assembly.includes?(:z)).to be false
    end
  end

  describe '#state' do
    it 'returns :dormant for stable inactive assembly' do
      expect(assembly.state).to eq(:dormant)
    end

    it 'returns :active when recently activated' do
      assembly.activate
      expect(assembly.state).to eq(:active)
    end

    it 'returns :dissolving when coherence is low' do
      assembly.coherence = 0.1
      expect(assembly.state).to eq(:dissolving)
    end
  end

  describe '#to_h' do
    it 'returns hash with all fields' do
      h = assembly.to_h
      expect(h).to include(:id, :members, :member_count, :coherence, :state, :state_label, :activation_count)
      expect(h[:member_count]).to eq(3)
    end
  end
end
