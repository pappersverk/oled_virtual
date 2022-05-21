# OLEDVirtual

OLEDVirtual is a virtual version of the [oled](https://github.com/pappersverk/oled) library.

Its main purpose it to reduce the roundtrip time during development 
by fully virtualizing the oled display.

It also comes with a `MultiDisplay` module to use both hardware and virtual display at the same time.

## Installation

The package can be installed
by adding `oled_virtual` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oled_virtual, "~> 0.1.0"}
  ]
end
```

## Quickstart

1. Define the display module

```elixir
defmodule MyApp.OledVirtual do
  use OLEDVirtual.Display, app: :my_app

  def on_display(data, dimensions) do
    # React to new frames
    payload = %{
      data: data,
      dimensions: dimensions
    }
    Phoenix.PubSub.broadcast(MyApp.PubSub, "oled-virtual", %{event: "on_display", payload: payload})
  end
end
```

2. Define the dimensions of the display

```elixir
config :my_app, MyApp.OledVirtual,
   width: 128,
   height: 64
```

3. Add the virtual display to your supervision tree.

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add this line
      MyApp.OledVirtual
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

4. Use it

```elixir
# Draw something
MyApp.OledVirtual.rect(0, 0, 127, 63)
MyApp.OledVirtual.line(0, 0, 127, 63)
MyApp.OledVirtual.line(0, 63, 127, 0)

# Display it!
MyApp.OledVirtual.display()
```

---

The whole documentation can be found at [https://hexdocs.pm/oled_virtual](https://hexdocs.pm/oled_virtual).

