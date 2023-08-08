defmodule WrapYourNif do
  @compile {:autoload, false}
  @on_load {:init, 0}
  @nif_path "priv/#{Mix.target()}/lib/libwrapyournif"

  def init do
    case load_nif() do
      :ok -> :ok
      err -> raise "Error loading NIF: #{inspect(err)}"
    end
  end

  defp load_nif do
    Application.app_dir(:wrap_your_nif, @nif_path)
    |> String.to_charlist()
    |> :erlang.load_nif(0)
  end

  def add_two_ints(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def multiply_three_doubles(_a, _b, _c), do: :erlang.nif_error(:nif_not_loaded)
end
