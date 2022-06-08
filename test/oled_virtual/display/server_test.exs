defmodule OLEDVirtual.Display.ServerTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog

  alias OLEDVirtual.Display.Server

  setup do
    {:ok, pid} =
      Server.start_link(%{
        width: 16,
        height: 8,
        on_display: [__MODULE__, :on_display_callback],
        on_buffer_update: [__MODULE__, :on_buffer_update_callback]
      })

    %{server: pid}
  end

  test "get_frame/1 returns the current frame", context do
    capture_log(fn ->
      Server.display(context.server)
    end)

    assert {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>} =
             Server.get_frame(context.server)
  end

  test "put_buffer/2 and get_buffer/1 retrieve and change the buffer", context do
    assert {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>} =
             Server.get_buffer(context.server)

    capture_log(fn ->
      Server.put_buffer(context.server, <<255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
    end)

    assert {:ok, <<255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>} =
             Server.get_buffer(context.server)
  end

  test "on_display callback gets called", context do
    assert capture_log(fn ->
             Server.display(context.server)
             # give the logger a bit of time to actually log the message
             Process.sleep(50)
           end) =~ "on_display_callback/2 called"
  end

  test "on_buffer_update callback gets called", context do
    assert capture_log(fn ->
             Server.put_pixel(context.server, 5, 5)
             Process.sleep(50)
           end) =~ "on_buffer_update_callback/2 called"
  end

  def on_display_callback(_data, _dimensions) do
    Logger.info("on_display_callback/2 called")
  end

  def on_buffer_update_callback(_data, _dimensions) do
    Logger.info("on_buffer_update_callback/2 called")
  end
end
