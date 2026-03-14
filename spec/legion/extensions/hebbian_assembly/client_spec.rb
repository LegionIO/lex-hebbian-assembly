# frozen_string_literal: true

RSpec.describe Legion::Extensions::HebbianAssembly::Client do
  subject(:client) { described_class.new }

  it 'includes Runners::HebbianAssembly' do
    expect(described_class.ancestors).to include(Legion::Extensions::HebbianAssembly::Runners::HebbianAssembly)
  end

  it 'supports full Hebbian learning lifecycle' do
    # Repeatedly co-activate a pattern
    10.times { client.co_activate_units(ids: %i[see dog bark]) }

    # Assembly should form
    assemblies = client.list_assemblies
    expect(assemblies[:count]).to be >= 1

    # Pattern completion: given "see" and "dog", predict "bark"
    completion = client.pattern_complete(partial_ids: %i[see dog])
    expect(completion[:success]).to be true
    expect(completion[:completion][:predicted]).to include(:bark)

    # Weights should be strong
    weight = client.query_weight(from: :see, to: :dog)
    expect(weight[:weight]).to be > 0.3

    # Find assemblies containing :dog
    dog_asms = client.assemblies_for(unit_id: :dog)
    expect(dog_asms[:count]).to be >= 1

    # Decay
    client.update_hebbian

    # Stats
    stats = client.hebbian_stats
    expect(stats[:stats][:units]).to eq(3)
  end
end
