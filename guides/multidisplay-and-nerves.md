# Multi Display and Nerves

Probably the most common use case for the [`MultiDisplay`](`OLEDVirtual.MultiDisplay`)
module is in a [Nerves](https://hexdocs.pm/nerves/) project where it invokes the virtual display 
during local development and both virtual and hardware display on the device.

This way, a potential web interface could always provide a preview of the image on the display.
To build the actual virtual display using [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/), 
check out [this guide](virtual-display-liveview.md).

## Project Setup

For this guide, we use a Nerves typical poncho structure.

```
my_app
|-- firmware
`-- my_app
```

The inner `my_app` folder contains a normal Phoenix project and the `firmware` folder the Nerves project.
For a more in-depth guide on this setup, refer to the official [Nerves + Phoenix guide](https://hexdocs.pm/nerves/user-interfaces.html).

The additional dependencies for both projects are as follows:

```elixir
# my_app/firmware/mix.exs

defp deps do
  [
    ...
    {:oled, "~> 0.3.5"},
    {:circuits_i2c, "~> 1.0", override: true}
  ]
end
```

```elixir
# my_app/my_app/mix.exs

defp deps do
  [
    ...
    {:oled_virtual, "~> 0.1.0"}
  ]
end
```

## Adding the OLED Display

The OLED display will be created inside the `firmware` project because it needs to interact with
the real hardware which is not available during local development. 

```elixir
# my_app/firmware/lib/my_app_firmware/oled_display.ex

defmodule MyAppFirmware.OledDisplay do
  use OLED.Display, app: :my_app_firmware
end
```

```elixir
# my_app/firmware/config/target.exs

config :my_app_firmware, MyAppFirmware.OledDisplay,
       device: "i2c-1",
       driver: :ssd1306,
       type: :i2c,
       width: 128,
       height: 64,
       rst_pin: 25,
       dc_pin: 24,
       address: 0x3C
```

This configuration is specific to the OLED Bonnet display. 
Your OLED display might need a slightly different configuration.
Please refer to the `OLED` documentation.

The `MyAppFirmware.OledDisplay` module needs to be added to the supervision tree.

```elixir
# my_app/firmware/lib/my_app_firmware/application.ex

def children(_target) do
  [
    MyAppFirmware.OledDisplay
  ]
end
```

## Adding the Virtual OLED Display

The virtual OLED display will be part of the `my_app` Phoenix project.

```elixir
# my_app/my_app/lib/my_app/oled_virtual_display.ex

defmodule MyApp.OledVirtualDisplay do
  use OLEDVirtual.Display, app: :my_app

  def on_display(data, dimensions) do
    # React to new frames
  end
end
```

```elixir
# my_app/my_app/config/config.exs

config :my_app, MyApp.OledVirtualDisplay,
       width: 128,
       height: 64
```

Make sure that the configured resolution is the same as on the hardware display.

The `MyApp.OledVirtualDisplay` module needs to be added to the supervision tree.

```elixir
# my_app/my_app/lib/my_app/application.ex

@impl true
def start(_type, _args) do
  children = [
    ...
    MyApp.OledVirtualDisplay
  ]
  
  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Adding the Multi Display

The multi display will also be part of the `my_app` Phoenix project,
and invoke either the virtual display or both displays, 
based on the specific configuration that is loaded during runtime. 

```elixir
# my_app/my_app/lib/my_app/multi_display.ex

defmodule MyApp.MultiDisplay do
  use OLEDVirtual.MultiDisplay, app: :my_app
end
```

Now, we need to configure it in both projects.

```elixir
# my_app/my_app/config/config.exs

config :my_app, MyApp.MultiDisplay,
       displays: [
         MyApp.OledVirtualDisplay
       ]
```

```elixir
# my_app/firmware/config/target.exs

config :my_app, MyApp.MultiDisplay,
       displays: [
         MyApp.OledVirtualDisplay,
         MyAppFirmware.OledDisplay
       ]
```

This is all it takes. From now on, all display interactions can be made through 
the `MyApp.MultiDisplay` module, which invokes the configured display modules.

If the Nerves firmware is built using the `firmware` project, the multi display will 
invoke both displays. And if the `my_app` Phoenix project is started locally for development,
only the virtual display will be invoked.
      
