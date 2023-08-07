defmodule WrapYourNifTest do
  use ExUnit.Case
  doctest WrapYourNif

  test "greets the world" do
    assert WrapYourNif.hello() == :world
  end
end
