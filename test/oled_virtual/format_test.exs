defmodule OLEDVirtual.FormatTest do
  use ExUnit.Case, async: true

  alias OLEDVirtual.Format

  test "as_matrix/2" do
    result = Format.as_matrix(<<255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255>>, 16)

    assert [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] = Enum.at(result, 0)
    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] = Enum.at(result, 1)
    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] = Enum.at(result, 2)
    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] = Enum.at(result, 3)
    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] = Enum.at(result, 4)
    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] = Enum.at(result, 5)
    assert [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] = Enum.at(result, 6)
    assert [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] = Enum.at(result, 7)
  end

  test "as_bits/1" do
    result = Format.as_bits(<<255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255>>)

    assert [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] = Enum.take(result, 16)
    assert [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] = Enum.take(result, -16)
  end
end
