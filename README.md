# Persistomata

Persistomata is an Elixir framework that provides an out-of-the-box event log implementation built on top of ClickHouse, integrated with Redis, RabbitMQ, and PostgreSQL. Here's a detailed overview of its main features and technologies:

## Core Features

- **Event Log Framework**: A ready-to-use implementation for event logging and persistence
- **Multi-Backend Support**: Integrated with multiple storage and messaging systems:
  - ClickHouse for event storage
  - Redis
  - RabbitMQ
  - PostgreSQL

## Technical Stack

### Main Components
- Built with Elixir (~> 1.12)
- Uses a supervision tree architecture for robust process management
- Implements telemetry for monitoring and metrics

### Key Dependencies
- `caterpillar`: For data transformation
- `finitomata`: State machine implementation
- `telemetria`: Telemetry and monitoring
- `rambla`: Message handling and routing
- `antenna`: Communication layer

### Development Features
- Comprehensive test coverage using ExCoveralls
- Code quality tools:
  - Credo for static code analysis
  - Dialyxir for type checking
  - Documentation generation with ExDoc
- Quality assurance workflows with format checking and strict code analysis

### Integration Features
- Configurable ClickHouse connection for event storage
- Telemetry backend implementation for monitoring
- Custom message encoding and matching through Rambla
- Flexible application configuration system

## Architecture
The project follows a modular architecture with:
- Supervisor-based process management
- Pluggable backends for different storage systems
- Event-driven design for message handling
- Configurable matching and encoding systems

## Development Status
The project appears to be in active development (version 0.1.0) with a focus on providing a robust event logging infrastructure that can be easily integrated into existing Elixir applications.

## Installation

```elixir
def deps do
  [
    {:persistomata, "~> 0.1"}
  ]
end
```

## [Documentation](https://hexdocs.pm/persistomata)
