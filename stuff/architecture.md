# Architecture

## 1. System Overview

Persistomata is an event logging framework that integrates several key components to provide robust state management and persistence capabilities. The system consists of four main components working together:

1. **Finitomata**: Manages long-lived objects through state machines
2. **Telemetria**: Captures state transitions and transforms them into events
3. **Antenna**: Provides sophisticated pub/sub notification routing
4. **Rambla**: Handles persistence to ClickHouse

## 2. Component Architecture

```mermaid
graph TB
    FSM[Finitomata State Machine] --> |state transitions| TEL[Telemetria Backend]
    TEL --> |finitomata/finitomata_bulk events| ANT[Antenna PubSub]
    ANT --> |matched events| RAM[Rambla Matcher]
    RAM --> |formatted data| CH[(ClickHouse)]
    
    subgraph "State Machine Layer"
    FSM
    end
    
    subgraph "Event Processing Layer"
    TEL
    ANT
    end
    
    subgraph "Persistence Layer"
    RAM
    CH
    end

    style FSM fill:#004,stroke:#333,stroke-width:2px
    style TEL fill:#400,stroke:#333,stroke-width:2px
    style ANT fill:#400,stroke:#333,stroke-width:2px
    style RAM fill:#040,stroke:#333,stroke-width:2px
    style CH fill:#000,stroke:#333,stroke-width:2px
```

## 3. Event Flow Sequence

```mermaid
sequenceDiagram
    participant FSM as Finitomata FSM
    participant TEL as Telemetria Backend
    participant ANT as Antenna
    participant RAM as Rambla
    participant CH as ClickHouse

    FSM->>TEL: State Transition Event
    Note over TEL: Transform to event format
    Note over TEL: Batch events if throttled
    TEL->>ANT: Publish :finitomata/:finitomata_bulk
    Note over ANT: Match on channels:<br/>[:init, :state_changed,<br/>:mutating, :errored]
    ANT->>RAM: Forward matched event
    Note over RAM: Transform for ClickHouse
    RAM->>CH: Store event data
```

## 4. Key Data Structures

### Telemetria Event Structure
```elixir
%{
  id: id,            # FSM identifier
  fini_id: fini_id,  # Finitomata instance ID
  fini_name: name,   # FSM name
  level: level,      # Log level
  type: type,        # Event type (init/state_changed/mutating/errored)
  group: group,      # Event group
  node: node(),      # Erlang node
  mfa: mfa,         # Function capture
  args: args,       # Event arguments
  result: result,   # Operation result
  now: timestamp,   # Event timestamp
  times: measurements # System time measurements
}
```

### Antenna Matching Patterns
```elixir
@match_channels [
  :init,
  :state_changed,
  :mutating,
  :errored
]
```

### Rambla ClickHouse Message Format
```elixir
%{
  table: table_name,
  message: %{
    created_at: timestamp,
    node: node_name,
    unique_integer: integer,
    id: fsm_id,
    name: fsm_name,
    channel: event_channel,
    type: event_type,
    payload: encoded_payload
  }
}
```

## 5. Component Responsibilities

### Finitomata
- Implements state machine behavior
- Manages state transitions
- Triggers transition callbacks
- Maintains payload consistency

### Telemetria Backend
- Captures FSM state changes
- Transforms transitions into events
- Supports event throttling
- Batches events when configured
- Publishes to Antenna system

### Antenna
- Provides pub/sub infrastructure
- Matches events against channels
- Routes events to appropriate handlers
- Supports pattern-based filtering

### Rambla
- Receives matched events
- Transforms data for persistence
- Manages ClickHouse connections
- Handles data encoding
- Ensures reliable storage

## 6. Configuration

### ClickHouse Connection
```elixir
config :rambla,
  clickhouse: [
    connections: [
      conn: "http://default:password@localhost:8123/default"
    ],
    channels: [
      finitomata: [connection: :conn]
    ]
  ]
```

### Telemetria Configuration
```elixir
config :telemetria,
  backend: Telemetria.Backend.Persistomata,
  throttle: %{
    Persistomata.Test.Turnstile => {1_000, :all}
  },
  purge_level: :debug,
  level: :info,
  events: []
```

The architecture ensures robust event logging and state management through:
- Decoupled components with clear responsibilities
- Configurable event processing and routing
- Reliable persistence to ClickHouse
- Support for event batching and throttling
- Flexible matching and transformation capabilities
