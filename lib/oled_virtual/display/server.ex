defmodule OLEDVirtual.Display.Server do
  @moduledoc """
  Virtual display server
  """

  alias OLEDVirtual.Config
  alias OLED.Display.Impl.SSD1306.Draw

  @doc false
  def start_link(config, opts \\ []) do
    GenServer.start_link(__MODULE__, config, opts)
  end

  @doc false
  def init(config) do
    case Config.validate(config) do
      :ok ->
        config = Map.new(config)

        buffer = get_clear_buffer(config, :off)
        frame = get_clear_buffer(config, :off)

        state = Map.merge(config, %{buffer: buffer, frame: frame})

        {:ok, state}

      {:error, error} -> {:stop, error}
    end
  end

  @doc false
  def display(server),
      do: GenServer.call(server, :display)

  @doc false
  def display_frame(server, data, opts \\ []),
      do: GenServer.call(server, {:display_frame, data, opts})

  @doc false
  def display_raw_frame(server, data, opts \\ []),
    do: GenServer.call(server, {:display_raw_frame, data, opts})

  @doc false
  def put_buffer(server, data),
    do: GenServer.call(server, {:put_buffer, data})

  @doc false
  def get_buffer(server),
    do: GenServer.call(server, :get_buffer)

  @doc false
  def clear(server, pixel_state \\ :off),
    do: GenServer.call(server, {:clear, pixel_state})

  @doc false
  def put_pixel(server, x, y, opts \\ []),
    do: GenServer.call(server, {:put_pixel, x, y, opts})

  @doc false
  def line(server, x1, y1, x2, y2, opts \\ []),
    do: GenServer.call(server, {:line, x1, y1, x2, y2, opts})

  @doc false
  def line_h(server, x, y, width, opts \\ []),
    do: GenServer.call(server, {:line_h, x, y, width, opts})

  @doc false
  def line_v(server, x, y, height, opts \\ []),
    do: GenServer.call(server, {:line_v, x, y, height, opts})

  @doc false
  def circle(server, x0, y0, r, opts),
    do: GenServer.call(server, {:circle, x0, y0, r, opts})

  @doc false
  def rect(server, x, y, width, height, opts),
    do: GenServer.call(server, {:rect, x, y, width, height, opts})

  @doc false
  def fill_rect(server, x, y, width, height, opts),
    do: GenServer.call(server, {:fill_rect, x, y, width, height, opts})

  @doc false
  def get_dimensions(server),
    do: GenServer.call(server, :get_dimensions)

  @doc false
  def get_frame(server),
    do: GenServer.call(server, :get_frame)

  @doc false
  def handle_call(:display, _from, %{buffer: buffer} = state) do
    state = %{state | frame: buffer}

    {:reply, :ok, state, {:continue, :notifiy_display}}
  end

  @doc false
  def handle_call({:display_frame, data, _opts}, _from, state) do
    if byte_size(data) == state.width * state.height / 8 do
      state = %{state | frame: data}

      {:reply, :ok, state, {:continue, :notifiy_display}}
    else
      {:reply, {:error, :invalid_data_size}, state}
    end
  end

  @doc false
  def handle_call({:display_raw_frame, _data, _opts}, _from, state) do
    # Not supported
    {:reply, :ok, state}
  end

  def handle_call({:clear, pixel_state}, _from, state) do
    buffer = get_clear_buffer(state, pixel_state)

    {:reply, :ok, %{state | buffer: buffer}, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:put_buffer, data}, _from, state) do
    state = %{state | buffer: data}

    {:reply, :ok, state}
  end

  def handle_call(:get_buffer, _from, %{buffer: buffer} = state) do
    {:reply, {:ok, buffer}, state}
  end

  def handle_call({:put_pixel, x, y, opts}, _from, state) do
    state = Draw.put_pixel(state, x, y, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:line, x1, y1, x2, y2, opts}, _from, state) do
    state = Draw.line(state, x1, y1, x2, y2, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:line_h, x, y, width, opts}, _from, state) do
    state = Draw.line_h(state, x, y, width, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:line_v, x, y, height, opts}, _from, state) do
    state = Draw.line_v(state, x, y, height, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:rect, x, y, width, height, opts}, _from, state) do
    state = Draw.rect(state, x, y, width, height, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:circle, x0, y0, r, opts}, _from, state) do
    state = Draw.circle(state, x0, y0, r, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call({:fill_rect, x, y, width, height, opts}, _from, state) do
    state = Draw.fill_rect(state, x, y, width, height, opts)

    {:reply, :ok, state, {:continue, :notifiy_buffer_update}}
  end

  def handle_call(:get_dimensions, _from, %{width: w, height: h} = state) do
    {:reply, {:ok, w, h}, state}
  end

  def handle_call(:get_frame, _from, %{frame: frame} = state) do
    {:reply, {:ok, frame}, state}
  end

  def handle_continue(:notifiy_display, %{on_display: callback} = state) do
    Task.start(fn ->
      [module, function] = callback

      dimensions = %{
        width: state.width,
        height: state.height
      }

      apply(module, function, [state.frame, dimensions])
    end)

    {:noreply, state}
  end
  def handle_continue(:notifiy_display, state), do: {:noreply, state}

  def handle_continue(:notifiy_buffer_update, %{on_buffer_update: callback} = state) do
    Task.start(fn ->
      [module, function] = callback

      dimensions = %{
        width: state.width,
        height: state.height
      }

      apply(module, function, [state.buffer, dimensions])
    end)

    {:noreply, state}
  end
  def handle_continue(:notifiy_buffer_update, state), do: {:noreply, state}

  def get_clear_buffer(%{width: width, height: height}, pixel_state) when pixel_state in [:on, :off] do
    value =
      case pixel_state do
        :off -> <<0::8>>
        :on -> <<0xFF::8>>
      end

    for _ <- 1..trunc(width * height / 8), into: <<>> do
      value
    end
  end
end
