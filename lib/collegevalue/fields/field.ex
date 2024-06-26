defmodule Collegevalue.Fields.Field do
  use Ecto.Schema

  @primary_key false
  schema "fields" do

    @derive {Phoenix.Param, key: :name}
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
