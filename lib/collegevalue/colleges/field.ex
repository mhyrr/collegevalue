defmodule Collegevalue.Colleges.Field do
  use Ecto.Schema

  @primary_key false
  schema "fields" do
    field :name, :string
    field :count, :integer
    field :debt_avg, :decimal
    field :debt_min, :decimal
    field :debt_max, :decimal
    field :earn_avg, :decimal
    field :earn_min, :decimal
    field :earn_max, :decimal
  end

end
