defmodule OLEDVirtual.MultiDisplay do
  @moduledoc """

  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, moduledoc: @moduledoc] do
      @moduledoc moduledoc
                 |> String.replace(
                   ~r/MyApp\.MyMultiDisplay/,
                   Enum.join(Module.split(__MODULE__), ".")
                 )
                 |> String.replace(~r/:my_app/, ":#{Atom.to_string(Keyword.fetch!(opts, :app))}")

      @app Keyword.fetch!(opts, :app)
      @me __MODULE__

      def module_config(),
        do: Application.get_env(@app, @me, [])

      def display() do
        execute(:display, [])
      end

      def display_frame(data, opts \\ []) do
        execute(:display_frame, [data, opts])
      end

      def display_raw_frame(data, opts \\ []) do
        execute(:display_raw_frame, [data, opts])
      end

      def clear() do
        execute(:clear, [])
      end

      def clear(pixelstate) do
        execute(:clear, [pixelstate])
      end

      def put_buffer(data) do
        execute(:put_buffer, [data])
      end

      def get_buffer() do
        execute(:get_buffer, [])
      end

      def put_pixel(x, y, opts \\ []) do
        execute(:put_pixel, [x, y, opts])
      end

      def line(x1, y1, x2, y2, opts \\ []) do
        execute(:line, [x1, y1, x2, y2, opts])
      end

      def line_h(x, y, width, opts \\ []) do
        execute(:line_h, [x, y, width, opts])
      end

      def line_v(x, y, height, opts \\ []) do
        execute(:line_v, [x, y, height, opts])
      end

      def rect(x, y, width, height, opts \\ []) do
        execute(:rect, [x, y, width, height, opts])
      end

      def circle(x0, y0, r, opts \\ []) do
        execute(:circle, [x0, y0, r, opts])
      end

      def fill_rect(x, y, width, height, opts \\ []) do
        execute(:fill_rect, [x, y, width, height, opts])
      end

      def get_dimensions() do
        execute(:get_dimensions, [])
      end

      defp execute(function, opts) when is_atom(function) and is_list(opts) do
        displays = Keyword.get(module_config(), :displays, [])

        displays
        |> Enum.map(fn display ->
          Task.async(fn ->
            start_time = :erlang.monotonic_time()

            result = apply(display, function, opts)

            end_time = :erlang.monotonic_time()
            duration = (end_time - start_time) / 1_000_000

            Task.start(fn ->
              :telemetry.execute(
                [:oled_virtual, :multi_display, function],
                %{duration: duration},
                %{display: display, multi_display: @me}
              )
            end)

            {display, result}
          end)
        end)
        |> Task.await_many()
      end
    end
  end
end
