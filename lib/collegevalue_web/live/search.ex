defmodule CollegevalueWeb.SearchLive do
  use Phoenix.LiveView

  alias Collegevalue.Colleges
  alias Collegevalue.Fields
  alias CollegevalueWeb.FieldsLive
  alias CollegevalueWeb.CollegesLive
  alias CollegevalueWeb.Router.Helpers, as: Routes
  alias CollegevalueWeb.Endpoint

  def render(assigns) do
    ~L"""
    <form class="bg-lightplain rounded px-2 pt-2 pb-2 mb-4 w-80" phx-change="suggest" phx-submit="search">
      <input class="shadow appearance-none border rounded w-full py-1 px-1 w-80"  type="text" name="q" value="<%= @query %>" list="matches" placeholder="Search Schools or Fields.. " phx-debounce="300"
             <%= if @loading, do: "readonly" %>/>
      <datalist id="matches">
        <%= for match <- @matches do %>
          <option class="block px-4 py-2 text-sm leading-5 text-green hover:bg-green hover:text-green focus:outline-none focus:bg-green focus:text-green" value="<%= match %>"><%= match %></option>
        <% end %>
      </datalist>
      <%= if @result do %><pre><%= @result %></pre><% end %>
    </form>
    """
  end

  def mount(_, _session, socket) do
    {:ok, assign(socket, query: nil, result: nil, loading: false, matches: [])}
  end

  def handle_event("suggest", %{"q" => query}, socket) when byte_size(query) <= 100 do

    colleges = Colleges.match_colleges_by_name(query)
    fields = Fields.match_fields_by_name(query)

    {:noreply, assign(socket, matches: colleges ++ fields )}
  end

  def handle_event("search", %{"q" => query}, socket) when byte_size(query) <= 100 do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query, result: "Searching...", loading: true, matches: [])}
  end

  def handle_info({:search, query}, socket) do

    IO.inspect(socket)

    case Colleges.get_college_by_name(query) do
      college when is_map(college) ->
        IO.inspect(college)
        {:noreply, socket |> redirect(to: Routes.college_path(socket, :show, query )) }
      nil ->
        {:noreply, socket |> push_redirect(to:  Routes.live_path(socket, CollegevalueWeb.FieldsLive.Show, query ))}
        # {:noreply, socket |> redirect(to: Routes.live_path(socket, CollegeValueWeb.FieldsLive.Show, query )) }
    end

  end
end
