# lex-hebbian-assembly

Hebbian cell assembly learning for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-hebbian-assembly` implements the classic Hebbian learning rule: units that are co-activated together have their mutual synaptic weights strengthened. Over repeated co-activations, tightly connected unit clusters are detected and promoted into named assemblies. Pattern completion allows a partial cue set to retrieve the full set of associated units.

Key capabilities:

- **Hebbian weight updates**: co-activate any set of unit IDs to strengthen their pairwise connections
- **Assembly detection**: clusters of mutually connected units (average weight >= 0.3, min 3 units) promoted to named assemblies
- **Pattern completion**: provide a partial cue set; retrieves all units reachable above the activation threshold
- **Weight decay**: periodic decay of all synaptic weights; dissolved assemblies are removed
- **State lifecycle**: assemblies progress through forming -> active -> primed -> dormant -> dissolving

## Installation

Add to your Gemfile:

```ruby
gem 'lex-hebbian-assembly'
```

Or install directly:

```
gem install lex-hebbian-assembly
```

## Usage

```ruby
require 'legion/extensions/hebbian_assembly'

client = Legion::Extensions::HebbianAssembly::Client.new

# Co-activate units that fired together
client.co_activate_units(unit_ids: [:concept_a, :concept_b, :concept_c])

# After repeated co-activations, assemblies are detected
client.list_assemblies
# => [{ id: "...", unit_ids: [:concept_a, :concept_b, :concept_c], state: :active }]

# Complete a partial pattern
client.pattern_complete(partial_ids: [:concept_a])
# => { completed_units: [:concept_a, :concept_b, :concept_c], ... }

# Inspect weights
client.query_weight(unit_id: :concept_a, other_id: :concept_b)
# => { weight: 0.45, label: :strong }

# Maintenance (also runs automatically every 60 seconds via actor)
client.update_hebbian

# Stats
client.hebbian_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `activate_unit` | Activate a single unit in the network |
| `co_activate_units` | Co-activate a set of units and run Hebbian weight update |
| `query_weight` | Return the synaptic weight between two units |
| `list_assemblies` | All assemblies with state and member count |
| `query_assembly` | Detail for a specific assembly |
| `pattern_complete` | Complete a partial activation pattern |
| `strongest_units` | Top N units by total outgoing weight |
| `assemblies_for` | All assemblies containing a given unit |
| `update_hebbian` | Decay cycle (weights and assembly states) |
| `hebbian_stats` | Summary: unit count, assembly count, avg weight |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
