defmodule OLEDVirtual.ConfigTest do
  use ExUnit.Case, async: true

  alias OLEDVirtual.Config

  defmodule DummyCallbackModule do
    def on_display(_frame, _dimensions), do: :ok
    def invalid_on_display(_frame), do: :ok

    def on_buffer_update(_frame, _dimensions), do: :ok
    def invalid_on_buffer_update(_frame), do: :ok
  end

  describe "validate/1" do
    test "config must be a keyword list or map" do
      assert {:error, _} = Config.validate(nil)
      assert {:error, _} = Config.validate(1)
      assert {:error, _} = Config.validate(1.5)
      assert {:error, _} = Config.validate(true)
      assert {:error, _} = Config.validate("foo")
      assert {:error, _} = Config.validate({:foo})
      assert :ok = Config.validate(%{width: 16, height: 8})
      assert :ok = Config.validate(width: 16, height: 8)
    end
  end

  describe "validate/2 for :width" do
    test "value must be a number" do
      assert :ok = Config.validate(%{width: 8}, :width)
      assert {:error, _} = Config.validate(%{width: nil}, :width)
      assert {:error, _} = Config.validate(%{width: :foo}, :width)
      assert {:error, _} = Config.validate(%{width: "foo"}, :width)
      assert {:error, _} = Config.validate(%{width: true}, :width)
    end

    test "value must be a multiple of 8" do
      assert :ok = Config.validate(%{width: 8}, :width)
      assert {:error, _} = Config.validate(%{width: 5}, :width)
    end

    test "value is required" do
      assert :ok = Config.validate(%{width: 8}, :width)
      assert {:error, _} = Config.validate(%{}, :width)
    end
  end

  describe "validate/2 for :height" do
    test "value must be a number" do
      assert :ok = Config.validate(%{height: 8}, :height)
      assert {:error, _} = Config.validate(%{height: nil}, :height)
      assert {:error, _} = Config.validate(%{height: :foo}, :height)
      assert {:error, _} = Config.validate(%{height: "foo"}, :height)
      assert {:error, _} = Config.validate(%{height: true}, :height)
    end

    test "value must be a multiple of 8" do
      assert :ok = Config.validate(%{height: 8}, :height)
      assert {:error, _} = Config.validate(%{height: 5}, :height)
    end

    test "value is required" do
      assert :ok = Config.validate(%{height: 8}, :height)
      assert {:error, _} = Config.validate(%{}, :height)
    end
  end

  describe "validate/2 for :on_display" do
    test "value must be [mod, func]" do
      assert :ok = Config.validate(%{on_display: [DummyCallbackModule, :on_display]}, :on_display)
      assert {:error, _} = Config.validate(%{on_display: nil}, :on_display)
      assert {:error, _} = Config.validate(%{on_display: 1}, :on_display)
      assert {:error, _} = Config.validate(%{on_display: :foo}, :on_display)
      assert {:error, _} = Config.validate(%{on_display: "foo"}, :on_display)
      assert {:error, _} = Config.validate(%{on_display: true}, :on_display)
    end

    test "[mod, func] must exist with an arity of 2" do
      assert :ok = Config.validate(%{on_display: [DummyCallbackModule, :on_display]}, :on_display)

      assert {:error, _} =
               Config.validate(
                 %{on_display: [DummyCallbackModule, :invalid_on_display]},
                 :on_display
               )
    end

    test "value can be optional" do
      assert :ok = Config.validate(%{}, :on_display)
    end
  end

  describe "validate/2 for :on_buffer_update" do
    test "value must be [mod, func]" do
      assert :ok =
               Config.validate(
                 %{on_buffer_update: [DummyCallbackModule, :on_buffer_update]},
                 :on_buffer_update
               )

      assert {:error, _} = Config.validate(%{on_buffer_update: nil}, :on_buffer_update)
      assert {:error, _} = Config.validate(%{on_buffer_update: 1}, :on_buffer_update)
      assert {:error, _} = Config.validate(%{on_buffer_update: :foo}, :on_buffer_update)
      assert {:error, _} = Config.validate(%{on_buffer_update: "foo"}, :on_buffer_update)
      assert {:error, _} = Config.validate(%{on_buffer_update: true}, :on_buffer_update)
    end

    test "[mod, func] must exist with an arity of 2" do
      assert :ok =
               Config.validate(
                 %{on_buffer_update: [DummyCallbackModule, :on_buffer_update]},
                 :on_buffer_update
               )

      assert {:error, _} =
               Config.validate(
                 %{on_buffer_update: [DummyCallbackModule, :invalid_on_buffer_update]},
                 :on_buffer_update
               )
    end

    test "value can be optional" do
      assert :ok = Config.validate(%{}, :on_buffer_update)
    end
  end
end
