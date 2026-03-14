# lex-hebbian-assembly

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-hebbian-assembly`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::HebbianAssembly`

## Purpose

Hebbian cell assembly learning for LegionIO agents. Simulates "neurons that fire together wire together": units are activated individually or co-activated together, synaptic weights between co-active units are strengthened via Hebbian update, and units with strong mutual weights are detected and promoted into named assemblies. Pattern completion allows partial cue sets to retrieve full associated assemblies.

## Gem Info

- **Require path**: `legion/extensions/hebbian_assembly`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/hebbian_assembly/
  version.rb
  helpers/
    constants.rb          # Limits, weights, thresholds
    unit.rb               # Unit value object (synaptic node)
    assembly.rb           # Assembly value object (named unit cluster)
    assembly_network.rb   # Network store + Hebbian logic
  actors/
    decay.rb              # Decay actor (Every 60s)
  runners/
    hebbian_assembly.rb   # Runner module

spec/
  legion/extensions/hebbian_assembly/
    helpers/
      constants_spec.rb
      unit_spec.rb
      assembly_spec.rb
      assembly_network_spec.rb
    actors/decay_spec.rb
    runners/hebbian_assembly_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_UNITS             = 500
MAX_ASSEMBLIES        = 100
LEARNING_RATE         = 0.05   # weight increment per co-activation
WEIGHT_DECAY          = 0.002  # weight decrement per decay tick
ACTIVATION_THRESHOLD  = 0.3    # minimum weight to propagate activation
CO_ACTIVATION_WINDOW  = 5      # recent activation window for co-activation detection
ASSEMBLY_THRESHOLD    = 3      # minimum units in a stable cluster to form assembly
ASSEMBLY_MIN_WEIGHT   = 0.3    # minimum average mutual weight to qualify as assembly

WEIGHT_LABELS   # :weak / :moderate / :strong / :dominant (by weight ranges)
ASSEMBLY_STATE_LABELS  # :forming / :active / :primed / :dormant / :dissolving
```

## Helpers

### `Helpers::Unit` (class)

A single node in the Hebbian network, holding synaptic weights to other units.

| Method | Description |
|---|---|
| `activate` | marks unit as recently active, timestamps activation |
| `connect(other_id, weight: 0.0)` | initializes or retrieves a weight to another unit |
| `strengthen(other_id)` | increments weight by LEARNING_RATE (capped at 1.0) |
| `weaken(other_id)` | decrements weight by LEARNING_RATE (floor 0.0) |
| `decay_weights` | subtracts WEIGHT_DECAY from all outgoing weights; removes zero-weight connections |
| `weight_label(other_id)` | returns :weak/:moderate/:strong/:dominant for a given connection |

### `Helpers::Assembly` (class)

A named cluster of units that co-activate reliably.

| Method | Description |
|---|---|
| `activate` | marks assembly active, updates last_activated timestamp |
| `consolidate` | transitions forming -> active state |
| `decay` | weakens assembly toward dormant/dissolving based on inactivity |
| `dissolving?` | true if state is :dissolving |
| `state` | current state symbol (:forming, :active, :primed, :dormant, :dissolving) |

### `Helpers::AssemblyNetwork` (class)

Central store for all units and assemblies; implements Hebbian update logic.

| Method | Description |
|---|---|
| `activate_unit(unit_id)` | creates or retrieves unit, marks it active |
| `co_activate(unit_ids)` | activates all listed units and calls hebbian_update for all pairs |
| `hebbian_update` | scans recently co-active unit pairs, strengthens mutual weights |
| `detect_assemblies` | groups units whose average mutual weight exceeds ASSEMBLY_MIN_WEIGHT into named assemblies |
| `pattern_complete(partial_ids)` | given partial cue, returns units reachable above ACTIVATION_THRESHOLD |
| `decay_all` | calls decay_weights on all units, decay on all assemblies; removes dissolved assemblies |

## Actors

**`Actors::Decay`** — fires every 60 seconds, calls `update_hebbian` on the runner to decay all weights and assemblies.

## Runners

Module: `Legion::Extensions::HebbianAssembly::Runners::HebbianAssembly`

Private state: `@network` (memoized `AssemblyNetwork` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `activate_unit` | `unit_id:` | Activate a single unit in the network |
| `co_activate_units` | `unit_ids:` | Co-activate a set of units and run Hebbian update |
| `query_weight` | `unit_id:, other_id:` | Return the synaptic weight between two units |
| `list_assemblies` | (none) | All assemblies with state and member count |
| `query_assembly` | `assembly_id:` | Detail for a specific assembly |
| `pattern_complete` | `partial_ids:` | Complete a partial activation pattern |
| `strongest_units` | `limit: 10` | Units with highest total outgoing weight |
| `assemblies_for` | `unit_id:` | Assemblies containing a given unit |
| `update_hebbian` | (none) | Trigger decay cycle (called by actor) |
| `hebbian_stats` | (none) | Summary: unit count, assembly count, avg weight |

## Integration Points

- **lex-memory**: `hebbian_link` in lex-memory directly co-activates memory trace pairs; lex-hebbian-assembly is the standalone unit-level model for non-memory networks.
- **lex-coldstart**: Claude context ingestion co-activates traces from the same markdown section to seed Hebbian associations in lex-memory.
- **lex-dream**: `association_walk` phase traverses Hebbian links built during prior ticks.
- **lex-metacognition**: `HebbianAssembly` is listed under `:cognition` capability category.

## Development Notes

- Unit IDs are arbitrary strings (typically symbols cast to string or UUIDs). No schema enforcement.
- `hebbian_update` only processes pairs where both units were activated within `CO_ACTIVATION_WINDOW` recent entries. Units activated far apart in time do not get weight updates.
- `detect_assemblies` is a greedy clustering pass, not a full graph community detection algorithm. Two units qualify for the same assembly if their mutual weight meets `ASSEMBLY_MIN_WEIGHT`; there is no transitive closure guarantee.
- `pattern_complete` returns all units reachable from the partial cue set by following edges above `ACTIVATION_THRESHOLD`. It does not limit depth — for densely connected networks this could return many units.
- `decay_all` removes dissolved assemblies permanently. Units themselves are not removed by decay; only their weights are reduced.
- No actor for assembly promotion — `detect_assemblies` is called on-demand from the runner, not on a schedule.
