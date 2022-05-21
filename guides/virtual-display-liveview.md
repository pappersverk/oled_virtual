# Virtual Display Using LiveView

The entire point of this library is to provide a virtual abstraction 
of the hardware OLED display. But for proper usage, the virtual OLED display
actually needs to be displayed somewhere, preferably via a web interface.

This guide will show an example using [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
as it is probably the simplest solution when using a Phoenix project anyway.

## High Level Concept

The idea is simple. The virtual display module supports an `on_display/2` callback, which is called whenever a new frame needs to be rendered. 
The callback can be used to broadcast the frame data using `Phoenix.PubSub`, 
which a LiveView can subscribe to. The LiveView then pushes the frame data via an event 
to the browser client. A custom LiveView hook on the client receives the event and renders the frame on a canvas. 

## Broadcasting New Frames

The `on_display/2` callback on the display module gets called on each new frame,
which will be used to broadcast the frame data and dimensions using `Phoenix.PubSub`.

```elixir
# my_app/lib/my_app/oled_virtual_display.ex

defmodule MyApp.OledVirtualDisplay do
  use OLEDVirtual.Display, app: :my_app

  def on_display(data, dimensions) do
    payload = %{
      data: data,
      dimensions: dimensions
    }
    Phoenix.PubSub.broadcast(MyApp.PubSub, "oled-virtual", %{event: "on_display", payload: payload})
  end
end
```

## Adding the LiveView

Below is the entire LiveView module. 

It sends an initial `setup` event to the browser client to render the first frame,
then listens for new frames to also send them to the browser client.

```elixir
# my_app/lib/my_app_web/live/oled_virtual.ex

defmodule MyAppWeb.OledVirtualLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.Endpoint
  alias MyApp.OledVirtualDisplay
  alias OLEDVirtual.Format

  @impl true
  def render(assigns) do
    ~H"""
      <div id={"oled-virtual-#{@id}"} phx-hook="OledVirtual">
        <div phx-update="ignore">
          <div data-element="canvas-container"></div>
        </div>
      </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("oled-virtual")
    end

    {:ok, width, height} = OledVirtualDisplay.get_dimensions()
    {:ok, frame} = OledVirtualDisplay.get_frame()

    setup_event_payload = %{
      data: Format.as_bits(frame),
      dimensions: %{
        width: width,
        height: height
      }
    }

    socket =
      socket
      |> assign(width: width)
      |> assign(height: height)
      |> assign(id: socket.id)
      |> push_event("setup", setup_event_payload)

    {:ok, socket, layout: {MyAppWeb.LayoutView, "live_empty.html"}}
  end

  @impl true
  def handle_info(%{event: "on_display", payload: %{data: data}}, socket) do
    payload = %{
      data: Format.as_bits(data)
    }

    {:noreply, push_event(socket, "new_frame", payload)}
  end
end
```

The `mount/3` function sets a custom `live_empty.html` layout, 
which lives next to the default `live.html`. Its usage is optional,
but makes for a cleaner HTML.

```elixir
# my_app/lib/my_app_web/templates/layout/live_empty.html.heex

<%= @inner_content %>
```

## Adding the LiveView Hook

The template in the LiveView module above uses a custom `OledVirtual` hook on the outer `div`.

Below is the entire LiveView hook.

It handles the canvas creation in the `setup` event handler 
and updates the canvas on every `new_frame` event.

```javascript
// my_app/assets/js/app.js

let Hooks = {}

Hooks.OledVirtual = {
  mounted() {
    const container = this.el.querySelector('[data-element="canvas-container"]');

    this.handleEvent("setup", (payload) => {
      const existingCanvas = container.getElementsByTagName('canvas') ;
      if (existingCanvas.length) {
        Array.from(existingCanvas).map((c) => c.remove());
      }

      const canvas = document.createElement('canvas');
      canvas.width = payload.dimensions.width;
      canvas.height = payload.dimensions.height;

      const scale = 2;
      canvas.style.imageRendering = 'pixelated';
      canvas.style.transformOrigin = 'top left';
      canvas.style.transform = `scale(${scale})`;

      container.style.width = `${payload.dimensions.width * scale}px`;
      container.style.height = `${payload.dimensions.height * scale}px`;

      const ctx = canvas.getContext('2d');

      container.appendChild(canvas);

      displayImage(ctx, payload.dimensions, payload.data);

      this.ctx = ctx;
      this.dimensions = payload.dimensions;
    });

    this.handleEvent("new_frame", (payload) => {
      displayImage(this.ctx, this.dimensions, payload.data);
    });
  }
}

const displayImage = (ctx, dimensions, data) => {
  const imgData = ctx.createImageData(dimensions.width, dimensions.height);

  let i;
  for (i = 0; i < imgData.data.length; i += 1) {
    const color = data[i] === 1 ? 255 : 0;

    imgData.data[(i * 4)] = color;
    imgData.data[1 + (i * 4)] = color;
    imgData.data[2 + (i * 4)] = color;
    imgData.data[3 + (i * 4)] = 255;
  }
  ctx.putImageData(imgData, 0, 0);
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken},
})
```

## Using the LiveView

The LiveView can be rendered inside or outside existing live views using the `live_render` function.

```heex
<%= live_render(@conn, MyAppWeb.OledVirtualLive, id: "oled-virtual") %>
```

The exact place depends on the specific application. 
A simple setup might have it directly inside `root.html.heex` 
so it is always visible on the web-interface.
