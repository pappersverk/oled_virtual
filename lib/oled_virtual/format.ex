defmodule OLEDVirtual.Format do
  @moduledoc """

  """

  def as_matrix(data, width) when is_binary(data) and is_number(width) do
    data
    |> extract_bits()
    |> Enum.chunk_every(width)
  end

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
