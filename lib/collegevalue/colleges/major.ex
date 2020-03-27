defmodule Collegevalue.Colleges.Major do
use Ecto.Schema

  schema "majors" do
    field :credential_desc, :string
    field :credential_level, :integer
    field :debt_count, :integer
    field :debt_mean, :integer
    field :debt_median, :integer
    field :earnings, :integer
    field :earnings_count, :integer
    field :name, :string
    field :college_name, :string
    field :url, :string
  end

end

