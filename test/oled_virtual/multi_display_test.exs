defmodule OLEDVirtual.MultiDisplayTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  setup_all do
    Application.put_env(:olev_virtual_test, OLEDVirtual.TestMultiDisplay,
      displays: [
        OLEDVirtual.TestDisplayOne,
        OLEDVirtual.TestDisplayTwo
      ]
    )
  end

  test "invokes a function on all configured displays" do
    fun = fn ->
      assert [{OLEDVirtual.TestDisplayOne, :ok}, {OLEDVirtual.TestDisplayTwo, :ok}] =
               OLEDVirtual.TestMultiDisplay.display()
    end

    assert capture_log(fun) =~ "display/0 on TestDisplayOne"
    assert capture_log(fun) =~ "display/0 on TestDisplayTwo"
  end

  test "sends a telemetry event per display function invocation", context do
    self = self()

    # telemetry handler is inside capture_log to prevent log message about anonymous function
    capture_log(fn ->
      :telemetry.attach(
        "#{context.test}",
        [:oled_virtual, :multi_display, :display],
        fn name, measurements, metadata, _ ->
          send(self, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )
    end)

    capture_log(fn ->
      OLEDVirtual.TestMultiDisplay.display()
    end)

    assert_receive {:telemetry_event, [:oled_virtual, :multi_display, :display], %{duration: _},
                    %{
                      display: OLEDVirtual.TestDisplayOne,
                      multi_display: OLEDVirtual.TestMultiDisplay
                    }}

    assert_receive {:telemetry_event, [:oled_virtual, :multi_display, :display], %{duration: _},
                    %{
                      display: OLEDVirtual.TestDisplayTwo,
                      multi_display: OLEDVirtual.TestMultiDisplay
                    }}
  end
end
