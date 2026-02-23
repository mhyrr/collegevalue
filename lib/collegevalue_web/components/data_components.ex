defmodule CollegevalueWeb.DataComponents do
  use Phoenix.Component

  alias CollegevalueWeb.Views.Helpers

  attr :value, :integer, required: true
  def diff_cell(assigns) do
    assigns = assign(assigns, :display, Helpers.cash(assigns.value))
    assigns = assign(assigns, :positive?, !Helpers.no_data?(assigns.value) && assigns.value > 0)
    assigns = assign(assigns, :no_data?, Helpers.no_data?(assigns.value))

    ~H"""
    <%= cond do %>
      <% @no_data? -> %>
        <td class="px-4 py-3 md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b text-gray-400 italic">
          N/A
        </td>
      <% @positive? -> %>
        <td class="px-4 py-3 md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b font-bold text-lg text-emerald-600">
          <%= @display %>
        </td>
      <% true -> %>
        <td class="px-4 py-3 md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b font-bold text-lg text-red-500">
          <%= @display %>
        </td>
    <% end %>
    """
  end

  attr :value, :any, default: nil
  def no_data_cell(assigns) do
    assigns = assign(assigns, :no_data?, Helpers.no_data?(assigns.value))
    assigns = assign(assigns, :display, Helpers.cash(assigns.value))

    ~H"""
    <%= if @no_data? do %>
      <td class="px-4 py-3 md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b text-gray-400 italic">
        N/A
      </td>
    <% else %>
      <td class="px-4 py-3 md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b">
        <%= @display %>
      </td>
    <% end %>
    """
  end

  attr :rate, :float, default: nil
  def completion_badge(assigns) do
    assigns = assign(assigns, :category, completion_category(assigns.rate))

    ~H"""
    <%= case @category do %>
      <% :high -> %>
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
          High Completion
        </span>
      <% :average -> %>
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
          Average
        </span>
      <% :low -> %>
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
          Low Completion
        </span>
      <% :no_data -> %>
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-500">
          N/A
        </span>
    <% end %>
    """
  end

  attr :rate, :float, default: nil
  attr :label, :string, default: ""
  def completion_bar(assigns) do
    assigns = assign(assigns, :width, bar_width(assigns.rate))
    assigns = assign(assigns, :color, bar_color(assigns.rate))
    assigns = assign(assigns, :display, format_percent(assigns.rate))

    ~H"""
    <div class="flex items-center gap-3 mb-2">
      <span class="text-sm text-gray-600 w-20 shrink-0"><%= @label %></span>
      <div class="flex-1 bg-gray-200 rounded-full h-4 relative">
        <div class={"#{@color} h-4 rounded-full"} style={"width: #{@width}%"}></div>
      </div>
      <span class="text-sm font-medium w-14 text-right"><%= @display %></span>
    </div>
    """
  end

  @th_class "px-4 py-3 border-b border-green bg-gray-50 text-left xl:text-sm leading-4 font-medium text-darkgreen uppercase md:tracking-wider tracking-tight"

  @tooltips %{
    "name" => "Institution name",
    "tuition" => "Published in-state tuition and fees per year",
    "admissions" => "Percentage of applicants who are admitted",
    "sat" => "Average SAT score of admitted students (combined reading + math)",
    "debt_median" => "Median federal loan debt at graduation for all students at this college",
    "debt_mean" => "Average federal loan debt at graduation — can be skewed by outliers, unlike the median",
    "earnings" => "Median earnings 10 years after enrollment, from tax records (W-2 data)",
    "earnings10yr" => "Median earnings 10 years after enrollment for all graduates of this college (not major-specific)",
    "earnings1yr" => "Median earnings 1 year after graduation for this specific major at this college",
    "earnings2yr" => "Median earnings 2 years after graduation for this specific major at this college",
    "difference" => "Earnings minus debt — a simple ROI measure. Higher is better. Green means graduates earn more than they borrowed.",
    "college_debt_median" => "Published in-state tuition and fees per year",
    "completion" => "Percentage of first-time, full-time students who graduate within 8 years (200% of normal time)",
    "credential_level" => "Degree type: Certificate, Associate's, Bachelor's, Master's, etc.",
    "major" => "The specific field of study / program",
    "field" => "The specific field of study / program"
  }

  # Sortable table header with tooltip and sort indicator
  # Used in LiveView tables with phx-click sorting
  attr :label, :string, required: true
  attr :sort_key, :string, required: true
  attr :current_sort, :string, default: nil
  attr :order, :string, default: "desc"
  attr :sort_event, :string, default: "sort"
  attr :tooltip, :string, default: nil
  def sort_header(assigns) do
    tip = assigns.tooltip || Map.get(@tooltips, assigns.sort_key, nil)
    active = assigns.current_sort == assigns.sort_key
    arrow = if active, do: (if assigns.order == "desc", do: "▼", else: "▲"), else: nil
    assigns = assign(assigns, tip: tip, active: active, arrow: arrow, th_class: @th_class)

    ~H"""
    <th class={@th_class}>
      <div class="flex items-center gap-1">
        <a href="#" class={"text-darkgreen #{if @active, do: "font-bold underline", else: ""}"} phx-click={@sort_event} phx-value-sort={@sort_key}>
          <%= @label %><%= if @arrow do %> <span class="text-[10px]"><%= @arrow %></span><% end %>
        </a>
        <%= if @tip do %>
          <span class="group relative">
            <span class="inline-flex items-center justify-center w-4 h-4 rounded-full bg-gray-200 text-gray-500 text-[10px] font-bold cursor-help normal-case">?</span>
            <span class="hidden group-hover:block absolute z-10 bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 px-3 py-2 text-xs font-normal normal-case tracking-normal text-white bg-gray-800 rounded-lg shadow-lg">
              <%= @tip %>
            </span>
          </span>
        <% end %>
      </div>
    </th>
    """
  end

  # Sortable header using <.link patch=...> for URL-based sorting (field show page)
  attr :label, :string, required: true
  attr :sort_key, :string, required: true
  attr :current_sort, :string, default: nil
  attr :order, :string, default: "desc"
  attr :patch_url, :string, required: true
  attr :tooltip, :string, default: nil
  def sort_header_link(assigns) do
    tip = assigns.tooltip || Map.get(@tooltips, assigns.sort_key, nil)
    active = assigns.current_sort == assigns.sort_key
    arrow = if active, do: (if assigns.order == "desc", do: "▼", else: "▲"), else: nil
    assigns = assign(assigns, tip: tip, active: active, arrow: arrow, th_class: @th_class)

    ~H"""
    <th class={@th_class}>
      <div class="flex items-center gap-1">
        <.link patch={@patch_url} class={"text-darkgreen uppercase #{if @active, do: "font-bold underline", else: ""}"}>
          <%= @label %><%= if @arrow do %> <span class="text-[10px]"><%= @arrow %></span><% end %>
        </.link>
        <%= if @tip do %>
          <span class="group relative">
            <span class="inline-flex items-center justify-center w-4 h-4 rounded-full bg-gray-200 text-gray-500 text-[10px] font-bold cursor-help normal-case">?</span>
            <span class="hidden group-hover:block absolute z-10 bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 px-3 py-2 text-xs font-normal normal-case tracking-normal text-white bg-gray-800 rounded-lg shadow-lg">
              <%= @tip %>
            </span>
          </span>
        <% end %>
      </div>
    </th>
    """
  end

  # Non-sortable header with tooltip (for rank tables and static headers)
  attr :label, :string, required: true
  attr :tooltip_key, :string, default: nil
  attr :tooltip, :string, default: nil
  def header(assigns) do
    tip = assigns.tooltip || Map.get(@tooltips, assigns.tooltip_key, nil)
    assigns = assign(assigns, tip: tip, th_class: @th_class)

    ~H"""
    <th class={@th_class}>
      <div class="flex items-center gap-1">
        <span><%= @label %></span>
        <%= if @tip do %>
          <span class="group relative">
            <span class="inline-flex items-center justify-center w-4 h-4 rounded-full bg-gray-200 text-gray-500 text-[10px] font-bold cursor-help normal-case">?</span>
            <span class="hidden group-hover:block absolute z-10 bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 px-3 py-2 text-xs font-normal normal-case tracking-normal text-white bg-gray-800 rounded-lg shadow-lg">
              <%= @tip %>
            </span>
          </span>
        <% end %>
      </div>
    </th>
    """
  end

  defp th_class, do: @th_class

  defp completion_category(nil), do: :no_data
  defp completion_category(rate) when rate < 0, do: :no_data
  defp completion_category(rate) when rate >= 0.70, do: :high
  defp completion_category(rate) when rate >= 0.40, do: :average
  defp completion_category(_rate), do: :low

  defp bar_width(nil), do: 0
  defp bar_width(rate) when rate < 0, do: 0
  defp bar_width(rate), do: Float.round(rate * 100, 1)

  defp bar_color(nil), do: "bg-gray-300"
  defp bar_color(rate) when rate < 0, do: "bg-gray-300"
  defp bar_color(rate) when rate >= 0.70, do: "bg-emerald-500"
  defp bar_color(rate) when rate >= 0.40, do: "bg-amber-500"
  defp bar_color(_), do: "bg-red-500"

  defp format_percent(nil), do: "N/A"
  defp format_percent(rate) when rate < 0, do: "N/A"
  defp format_percent(rate), do: "#{Float.round(rate * 100, 1)}%"
end
