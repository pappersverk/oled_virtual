defmodule OLEDVirtual.Format do
  @moduledoc """
  A set of helper functions to format the frame data.
  """

  @doc """
  Formats the frame data into a nested array with rows and columns.
  A value of `1` means the pixel is on and a value of `0` means the pixel is off.

      {:ok, width, _height} = MyApp.MyDisplay.get_dimensions()
      {:ok, frame} = MyApp.MyDisplay.get_frame()

      pixel_matrix = OLEDVirtual.Format.as_matrix(frame, width)
  """
  def as_matrix(data, width) when is_binary(data) and is_number(width) do
    data
    |> extract_bits()
    |> Enum.chunk_every(width)
  end

  @doc """
  Formats the frame data into a list of bit values.
  A value of `1` means the pixel is on and a value of `0` means the pixel is off.

      {:ok, frame} = MyApp.MyDisplay.get_frame()

      bits = OLEDVirtual.Format.as_bits(frame)
  """
  def as_bits(data) when is_binary(data) do
    data |> extract_bits()
  end

  defp extract_bits(data) when is_binary(data) do
    extract_bits(data, [])
  end

  defp extract_bits(<<b::size(1), bits::bitstring>>, acc) when is_bitstring(bits) do
    extract_bits(bits, [b | acc])
  end

  defp extract_bits(<<>>, acc), do: acc |> Enum.reverse()
end
