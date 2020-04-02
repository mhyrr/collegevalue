defmodule CollegevalueWeb.SearchLive do
  use Phoenix.LiveView

  alias Collegevalue.Colleges
  alias Collegevalue.Fields
  alias CollegevalueWeb.FieldsLive
  alias CollegevalueWeb.Router.Helpers, as: Routes

  def render(assigns) do
    ~L"""
    <form phx-change="suggest" phx-submit="search">
      <input type="text" name="q" value="<%= @query %>" list="matches" placeholder="Search..."
             <%= if @loading, do: "readonly" %>/>
      <datalist id="matches">
        <%= for match <- @matches do %>
          <option value="<%= match %>"><%= match %></option>
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

    case Colleges.get_college_by_name(query) do
      college when is_map(college) ->
        {:stop, socket |> redirect(to: Routes.college_path(socket, :show, college.id )) }
      nil ->
        {:stop, socket |> redirect(to: Routes.live_path(socket, FieldsLive.Show, query )) }

    end

  end
end
