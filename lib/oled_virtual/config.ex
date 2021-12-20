defmodule OLEDVirtual.Config do
  @moduledoc """

  """

  def validate(config) when is_list(config) do
    case Keyword.keyword?(config) do
      true -> validate(Map.new(config))
      false -> {:error, "config must be a keyword list or map"}
    end
  end

  def validate(config) when is_map(config) do
    keys = [:width, :height, :on_display]

    Enum.reduce(keys, :ok, fn key, acc ->
      case acc do
        :ok -> validate(config, key)
        error -> error
      end
    end)
  end

  def validate(_), do:  {:error, "config must be a keyword list or map"}

  def validate(%{width: width}, :width) when is_number(width) do
    case rem(width, 8) do
      0 -> :ok
      _ ->  {:error, "config value 'width' must be a multiple of 8"}
    end
  end
  def validate(%{width: _}, :width), do: {:error, "config value 'width' must be a number"}
  def validate(_, :width), do: {:error, "config value 'width' is required"}

  def validate(%{height: height}, :height) when is_number(height) do
    case rem(height, 8) do
      0 -> :ok
      _ ->  {:error, "config value 'height' must be a multiple of 8"}
    end
  end
  def validate(%{height: _}, :height), do: {:error, "config value 'height' must be a number"}
  def validate(_, :height), do: {:error, "config value 'height' is required"}

  def validate(%{on_display: [mod, func]}, :on_display) when is_atom(mod) and is_atom(func) do
    case function_exported?(mod, func, 2) do
      true -> :ok
      false -> {:error, "optional config value 'on_display' must be of the format '[module, function]' where function has an arity of 2"}
    end
  end
  def validate(%{on_display: _}, :on_display) do
    {:error, "optional config value 'on_display' must be of the format '[module, function]' where function has an arity of 2"}
  end
  def validate(%{}, :on_display), do: :ok

  def validate(%{on_buffer_update: [mod, func]}, :on_buffer_update) when is_atom(mod) and is_atom(func) do
    case function_exported?(mod, func, 2) do
      true -> :ok
      false -> {:error, "optional config value 'on_buffer_update' must be of the format '[module, function]' where function has an arity of 2"}
    end
  end
  def validate(%{on_buffer_update: _}, :on_buffer_update) do
    {:error, "optional config value 'on_buffer_update' must be of the format '[module, function]' where function has an arity of 2"}
  end
  def validate(%{}, :on_buffer_update), do: :ok
end
