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
