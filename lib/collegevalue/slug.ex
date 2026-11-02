defmodule Collegevalue.Slug do
  @moduledoc "URL slugs: lowercase letters and digits joined by hyphens."

  def slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
