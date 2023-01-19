defmodule Collegevalue.Colleges.Major do
use Ecto.Schema
import Ecto.Changeset

  # Majors correspond to disciplines.  Map this out.

  schema "majors" do
    field :credential_desc, :string
    field :credential_level, :integer
    field :debt_count, :integer
    field :debt_mean, :integer
    field :debt_median, :integer
    field :earnings, :integer
    field :earnings_count, :integer
    field :name, :string
    field :unit_id, :integer
    field :college_name, :string
    field :college_id, :integer
    field :url, :string
  end

end
