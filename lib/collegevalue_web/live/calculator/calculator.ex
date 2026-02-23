defmodule CollegevalueWeb.CalculatorLive.Index do
  use Phoenix.LiveView

  import CollegevalueWeb.Views.Helpers
  import CollegevalueWeb.DataComponents
  alias CollegevalueWeb.Router.Helpers, as: Routes

  alias Collegevalue.Calculator

  @income_bands [
    {1, "$0 - $30,000"},
    {2, "$30,001 - $48,000"},
    {3, "$48,001 - $75,000"},
    {4, "$75,001 - $110,000"},
    {5, "$110,000+"}
  ]

  def mount(_params, _session, socket) do
    majors = Calculator.list_popular_majors()

    {:ok,
     assign(socket,
       page_title: "ROI Calculator",
       majors: majors,
       income_bands: @income_bands,
       income_band: 3,
       major: "",
       zip: "",
       distance: 50,
       sat: "",
       results: nil,
       error: nil,
       calculating: false
     )}
  end

  def handle_event("calculate", %{"calculator" => params}, socket) do
    zip = String.trim(params["zip"] || "")
    major = params["major"] || ""

    cond do
      zip == "" or not Regex.match?(~r/^\d{5}$/, zip) ->
        {:noreply, assign(socket, error: "Please enter a valid 5-digit zipcode.", results: nil)}

      major == "" ->
        {:noreply, assign(socket, error: "Please select a major.", results: nil)}

      true ->
        income_band = String.to_integer(params["income_band"] || "3")
        distance = String.to_integer(params["distance"] || "50")

        results = Calculator.calculate(%{
          income_band: income_band,
          major: major,
          zip: zip,
          distance: distance,
          sat: params["sat"]
        })

        {:noreply,
         assign(socket,
           results: results,
           error: nil,
           income_band: income_band,
           major: major,
           zip: zip,
           distance: distance,
           sat: params["sat"] || ""
         )}
    end
  end

  def handle_event("validate", %{"calculator" => params}, socket) do
    {:noreply,
     assign(socket,
       income_band: String.to_integer(params["income_band"] || "3"),
       major: params["major"] || "",
       zip: params["zip"] || "",
       distance: String.to_integer(params["distance"] || "50"),
       sat: params["sat"] || ""
     )}
  end
end
