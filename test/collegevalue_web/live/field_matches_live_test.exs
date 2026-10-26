defmodule CollegevalueWeb.FieldMatchesLiveTest do
  # Renders the matches template and drives the LiveView callbacks directly;
  # the LiveView test client would need the lazy_html dependency.
  use ExUnit.Case, async: true

  alias Collegevalue.Colleges.{College, Discipline}
  alias CollegevalueWeb.FieldsLive.Matches

  defp major(college, np3, np5, earnings, pp_debt) do
    %Discipline{name: "Economics", credential_level: 3, earnings_1yr: earnings, earnings_2yr: earnings,
                stgp_debt_median: 24_000, pp_debt_median: pp_debt,
                college: %College{name: college, unitid: System.unique_integer([:positive]), netprice_3: np3,
                                  netprice_5: np5, yearly_cost: 82_750, admissions_rate: 0.5, sat_avg: 1200,
                                  earnings_median_after10: 60_000}}
  end

  setup do
    majors = [major("Ithaca Test", 29_170, 45_000, 40_000, 81_077), major("Cheap Test", 2_167, -2, 20_000, -2)]
    {:ok, socket} = Matches.mount(:not_mounted_at_router, %{"majors" => majors, "stretch" => []}, %Phoenix.LiveView.Socket{})
    %{socket: socket}
  end

  defp html(socket) do
    assigns = Map.put(socket.assigns, :socket, CollegevalueWeb.Endpoint)
    Phoenix.View.render_to_string(CollegevalueWeb.FieldView, "matches.html", assigns)
  end

  defp tbody(socket), do: socket |> html() |> String.split("<tbody") |> Enum.at(1)
  defp event(socket, name, params), do: socket |> then(&Matches.handle_event(name, params, &1)) |> elem(1)

  test "shows bracket 3 cost, gap and years of pay by default", %{socket: socket} do
    html = html(socket)

    assert socket.assigns.income == 3
    assert html =~ "Family income"
    assert html =~ "for families earning $48,000–75,000"
    assert html =~ "$116,680"
    assert html =~ "$93k beyond federal loans"
    assert html =~ "2.9 years"
    refute html =~ ">Tuition<"
  end

  test "shows the Parent PLUS warning past 24 months of pay", %{socket: socket} do
    # 81,077 / (40,000 / 12) = 24.3 months.
    assert html(socket) =~ "Parents who borrowed owed a median of $81,077 (24 months of pay)."
  end

  test "switching the income bracket changes the cost, and bad values mean bracket 3", %{socket: socket} do
    socket = event(socket, "income", %{"income" => "5"})
    assert html(socket) =~ "for families earning $110,000 or more"
    assert html(socket) =~ "$180,000"

    socket = event(socket, "income", %{"income" => "99"})
    assert socket.assigns.income == 3
    assert html(socket) =~ "$116,680"
  end

  test "sorting by years of pay puts the best value first", %{socket: socket} do
    # Cheap: 4 x 2,167 / 20,000 = 0.43 years; Ithaca: 2.9 years.
    socket = event(socket, "sort", %{"sort" => "value"})
    body = tbody(socket)
    assert :binary.match(body, "Cheap Test") < :binary.match(body, "Ithaca Test")

    socket = event(socket, "sort", %{"sort" => "value"})
    body = tbody(socket)
    assert :binary.match(body, "Ithaca Test") < :binary.match(body, "Cheap Test")
  end

  test "starts on the income from the cookie, and asks the browser to keep a new pick" do
    majors = [major("Ithaca Test", 29_170, 45_000, 40_000, -2)]
    {:ok, socket} = Matches.mount(:not_mounted_at_router, %{"majors" => majors, "stretch" => [], "income" => 5}, %Phoenix.LiveView.Socket{})
    assert socket.assigns.income == 5
    assert html(socket) =~ "$180,000"

    socket = event(socket, "income", %{"income" => "2"})
    assert ["remember_income", %{income: 2}] in pushed(socket)
  end

  test "all majors arrive fastest to repay first, with a note saying so" do
    majors = [major("Slow Test", -2, -2, 20_000, -2), major("Quick Test", -2, -2, 96_000, -2)]
    session = %{"majors" => majors, "stretch" => [], "all_majors" => true}
    {:ok, socket} = Matches.mount(:not_mounted_at_router, session, %Phoenix.LiveView.Socket{})

    body = tbody(socket)
    assert :binary.match(body, "Quick Test") < :binary.match(body, "Slow Test")
    assert html(socket) =~ "No major picked, so these are the 2 programs of any major near you that are fastest to repay."
  end

  test "picked majors keep the earnings order and no all-majors note", %{socket: socket} do
    refute html(socket) =~ "No major picked"
    assert socket.assigns.sort_by == "earnings1yr"
  end

  defp pushed(socket), do: socket.private |> Map.get(:live_temp, %{}) |> Map.get(:push_events, [])
end
