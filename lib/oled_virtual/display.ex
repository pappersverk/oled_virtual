defmodule OLEDVirtual.Display do
  @moduledoc """
  Defines a display module

  When used, the display expects an `:app` as option.
  The `:app` should be the app that has the configuration.

  Example:

      defmodule MyApp.MyDisplay do
        use OLEDVirtual.Display, app: :my_app
      end

  Could be configured with:
      config :my_app, MyApp.MyDisplay,
        width: 128,
        height: 64

  ## Configuration:

    * `:width` - Display width

    * `:height` - Display height
  """

  alias OLEDVirtual.Display.Server

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, moduledoc: @moduledoc] do
      @moduledoc moduledoc
                 |> String.replace(~r/MyApp\.MyDisplay/, Enum.join(Module.split(__MODULE__), "."))
                 |> String.replace(~r/:my_app/, ":#{Atom.to_string(Keyword.fetch!(opts, :app))}")

      @app Keyword.fetch!(opts, :app)
      @me __MODULE__

      @behaviour OLED.Display

      def module_config(),
        do: Application.get_env(@app, @me, [])

      def start_link(config \\ []) do
        module_config()
        |> Keyword.merge(config)
        |> Keyword.merge(on_display: [@me, :on_display])
        |> Keyword.merge(on_buffer_update: [@me, :on_buffer_update])
        |> Server.start_link(name: @me)
      end

      spec = [
        id: opts[:id] || @me,
        start: Macro.escape(opts[:start]) || quote(do: {@me, :start_link, [opts]}),
        restart: opts[:restart] || :permanent,
        type: :worker
      ]

      @doc false
      @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
      def child_spec(opts) do
        %{unquote_splicing(spec)}
      end

      def display(),
        do: Server.display(@me)

      def display_frame(data, opts \\ []),
        do: Server.display_frame(@me, data, opts)

      def display_raw_frame(data, opts \\ []),
        do: Server.display_raw_frame(@me, data, opts)

      def clear(),
        do: Server.clear(@me)

      def clear(pixel_state),
        do: Server.clear(@me, pixel_state)

      def put_buffer(data),
        do: Server.put_buffer(@me, data)

      def get_buffer(),
        do: Server.get_buffer(@me)

      def put_pixel(x, y, opts \\ []),
        do: Server.put_pixel(@me, x, y, opts)

      def line(x1, y1, x2, y2, opts \\ []),
        do: Server.line(@me, x1, y1, x2, y2, opts)

      def line_h(x, y, width, opts \\ []),
        do: Server.line_h(@me, x, y, width, opts)

      def line_v(x, y, height, opts \\ []),
        do: Server.line_v(@me, x, y, height, opts)

      def rect(x, y, width, height, opts \\ []),
        do: Server.rect(@me, x, y, width, height, opts)

      def circle(x0, y0, r, opts \\ []),
        do: Server.circle(@me, x0, y0, r, opts)

      def fill_rect(x, y, width, height, opts \\ []),
        do: Server.fill_rect(@me, x, y, width, height, opts)

      def get_dimensions(),
        do: Server.get_dimensions(@me)

      def get_frame(),
        do: Server.get_frame(@me)

      def on_display(_data, _dimensions) do
        :ok
      end

      def on_buffer_update(_data, _dimensions) do
        :ok
      end

      defoverridable child_spec: 1, on_display: 2, on_buffer_update: 2
    end
  end
end
