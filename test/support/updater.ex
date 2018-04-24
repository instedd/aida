defmodule Updater do
  def update(_, [], value), do: value

  def update(map, [key | path], value) when is_map(map) do
    current = Map.get(map, key)

    map
    |> Map.put(key, update(current, path, value))
  end

  def update(list, [index | path], value) when is_list(list) do
    List.update_at(list, index, &update(&1, path, value))
  end
end
