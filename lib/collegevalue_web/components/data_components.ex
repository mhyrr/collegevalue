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

  # Months of first-year pay to clear the debt. Lower is better: green within
  # a year of pay, amber within two, red past that. With `parent_debt` and
  # `earnings`, a large Parent PLUS median gets a warning beneath the figure;
  # it never changes the figure.
  attr :value, :any, default: nil
  attr :parent_debt, :any, default: nil
  attr :earnings, :any, default: nil
  def months_cell(assigns) do
    assigns =
      assign(assigns,
        display: Helpers.months(assigns.value),
        color: months_color(assigns.value),
        parent_note: Helpers.parent_plus_note(assigns.parent_debt, assigns.earnings)
      )

    ~H"""
    <td class="px-4 py-3 months-field md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b">
      <span class={@color}><%= @display %></span>
      <%= if @parent_note do %>
        <span class="parent-plus-warning block mt-1 w-32 md:w-auto whitespace-normal text-xs leading-4 text-gray-700" title={@parent_note}>
          <span class="inline-block px-2 py-0.5 mb-0.5 rounded-full bg-amber-100 text-amber-800 font-medium">Parent loans</span>
          <%= @parent_note %>
        </span>
      <% end %>
    </td>
    """
  end

  @gap_tip "What four years cost beyond the median federal student loan for this major: the part a family covers from savings, work, Parent PLUS or private loans."

  # Four years of net price after grants for the income bracket, with the
  # four-year sticker price and the gap federal loans leave beneath it.
  # `net_price` and `sticker` are yearly; `debt` is the program's median
  # student-loan debt.
  attr :net_price, :any, default: nil
  attr :sticker, :any, default: nil
  attr :debt, :any, default: nil
  attr :gap_as_tip, :boolean, default: false
  def cost_cell(assigns) do
    assigns =
      assign(assigns,
        cost: Collegevalue.Fields.four_year_cost(assigns.net_price),
        sticker_total: Collegevalue.Fields.four_year_cost(assigns.sticker),
        gap: Collegevalue.Fields.gap_after_loans(assigns.net_price, assigns.debt),
        gap_tip: @gap_tip
      )

    ~H"""
    <td class="px-4 py-3 cost4-field md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b">
      <%= if @cost do %>
        <span class="font-medium"><%= Helpers.cash(@cost) %></span>
      <% else %>
        <span class="text-gray-400 italic">No data</span>
      <% end %>
      <span class="block text-xs text-gray-500">Sticker: <%= if @sticker_total, do: Helpers.cash_compact(@sticker_total), else: "No data" %>
        <%= if @gap && @gap_as_tip do %><.info_tip tip={"#{Helpers.gap_text(@gap)}. #{@gap_tip}"} /><% end %>
      </span>
      <%= if @gap && !@gap_as_tip do %>
        <span class="gap-after-loans block w-28 md:w-auto whitespace-normal text-xs text-gray-700" title={@gap_tip}><%= Helpers.gap_text(@gap) %></span>
      <% end %>
    </td>
    """
  end

  # Years of first-year pay to cover four years of net price.
  attr :value, :any, default: nil
  attr :bold, :boolean, default: false
  def years_cell(assigns) do
    assigns = assign(assigns, :display, Helpers.years(assigns.value))

    ~H"""
    <td class="px-4 py-3 years-field md:border-none md:relative md:block xl:text-sm whitespace-nowrap border-b">
      <span class={[@display == "N/A" && "text-gray-400 italic", @display != "N/A" && @bold && "font-bold text-lg"]}><%= @display %></span>
    </td>
    """
  end

  defp months_color(months) when is_number(months) and months > 0 and months <= 12, do: "font-bold text-lg text-emerald-600"
  defp months_color(months) when is_number(months) and months > 0 and months <= 24, do: "font-bold text-lg text-amber-600"
  defp months_color(months) when is_number(months) and months > 0, do: "font-bold text-lg text-red-500"
  defp months_color(_months), do: "text-gray-400 italic"

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
    "cost4" => "Four years at the average yearly price after grants for aided first-time full-time students in this family-income bracket. It includes housing, food and books. Schools report it for the whole school, not each major. Families who get no aid pay closer to the sticker price. Below it: what's left after the median federal student loan, which a family covers from savings, work, Parent PLUS or private loans.",
    "value_years" => "Years of first-year pay it takes to equal the four-year cost: four years of net price divided by a year's pay. Lower is better.",
    "cost" => "Four years at the average yearly price after grants for aided first-time full-time students in this family-income bracket. It includes housing, food and books. Schools report it for the whole school, not each major. Families who get no aid pay closer to the sticker price. Below it: what's left after the median federal student loan, which a family covers from savings, work, Parent PLUS or private loans.",
    "value" => "Years of first-year pay it takes to equal the four-year cost: four years of net price divided by a year's pay. Lower is better.",
    "months" => "Months of first-year pay it takes to equal the debt: median student-loan debt divided by monthly pay. It uses gross pay, before taxes and bills, and counts only graduates who borrowed. Lower is better.",
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
        <.link patch={@patch_url} rel="nofollow" class={"text-darkgreen uppercase #{if @active, do: "font-bold underline", else: ""}"}>
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

  # A headline figure with a label above and a note below, as on the field and
  # college pages.
  attr :label, :string, required: true
  attr :note, :string, default: nil
  slot :inner_block, required: true
  def stat_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-gray-200 border-t-4 border-t-darkgreen p-4">
      <dt class="text-xs uppercase tracking-wider text-gray-500"><%= @label %></dt>
      <dd class="pt-1 text-2xl font-display text-darkgreen tabular-nums"><%= render_slot(@inner_block) %></dd>
      <%= if @note do %><dd class="text-sm text-gray-500"><%= @note %></dd><% end %>
    </div>
    """
  end

  # A row of links styled as a two-way or three-way switch, for choices that
  # change the URL, so each view is its own crawlable page.
  attr :label, :string, required: true
  attr :items, :list, required: true, doc: "{text, href, active?}"
  def link_switch(assigns) do
    ~H"""
    <div class="inline-flex flex-wrap rounded-lg border border-gray-200 bg-gray-50 p-1" role="group" aria-label={@label}>
      <%= for {text, href, active} <- @items do %>
        <a href={href} aria-current={active && "true"} class={["no-underline", toggle_class(active)]}><%= text %></a>
      <% end %>
    </div>
    """
  end

  # A small "?" that shows `tip` on hover.
  attr :tip, :string, required: true
  def info_tip(assigns) do
    ~H"""
    <span class="group relative inline-block align-middle" tabindex="0">
      <span class="inline-flex items-center justify-center w-4 h-4 rounded-full bg-gray-200 text-gray-500 text-[10px] font-bold cursor-help">?</span>
      <span class="hidden group-hover:block group-focus:block absolute z-10 bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 px-3 py-2 text-xs font-normal normal-case tracking-normal whitespace-normal text-white bg-gray-800 rounded-lg shadow-lg"><%= @tip %></span>
    </span>
    """
  end

  # A completion rate with a dot colored like `completion_badge`.
  attr :rate, :float, default: nil
  def completion_rate(assigns) do
    assigns = assign(assigns, dot: completion_dot(completion_category(assigns.rate)), display: format_percent(assigns.rate))

    ~H"""
    <span class="inline-flex items-center gap-1.5 tabular-nums">
      <span class={["inline-block w-2 h-2 rounded-full", @dot]}></span><%= @display %>
    </span>
    """
  end

  defp completion_dot(:high), do: "bg-emerald-500"
  defp completion_dot(:average), do: "bg-amber-400"
  defp completion_dot(:low), do: "bg-red-500"
  defp completion_dot(:no_data), do: "bg-gray-300"

  # Switches a program table between bachelor's programs and every credential.
  attr :show_all, :boolean, required: true
  attr :bachelors_count, :integer, required: true
  attr :all_count, :integer, required: true
  def credential_toggle(assigns) do
    ~H"""
    <div class="credential-toggle inline-flex shrink-0 rounded-lg border border-gray-200 bg-gray-50 p-1" role="group" aria-label="Credentials">
      <button type="button" phx-click="credentials" phx-value-show="bachelors" aria-pressed={to_string(!@show_all)} class={toggle_class(!@show_all)}>
        Bachelor's <span class="font-normal text-gray-400 tabular-nums"><%= delimited(@bachelors_count) %></span>
      </button>
      <button type="button" phx-click="credentials" phx-value-show="all" aria-pressed={to_string(@show_all)} class={toggle_class(@show_all)}>
        All credentials <span class="font-normal text-gray-400 tabular-nums"><%= delimited(@all_count) %></span>
      </button>
    </div>
    """
  end

  defp toggle_class(true), do: "px-4 py-1.5 text-sm rounded-md bg-white shadow text-darkgreen font-bold"
  defp toggle_class(false), do: "px-4 py-1.5 text-sm rounded-md text-gray-600 hover:text-darkgreen"

  # The line under a program table that counts the programs it leaves out.
  # `one` and `many` finish the sentence after the count.
  attr :count, :integer, required: true
  attr :one, :string, required: true
  attr :many, :string, required: true
  def no_data_note(assigns) do
    ~H"""
    <%= if @count > 0 do %>
      <p class="no-data-count pt-4 text-sm text-gray-500"><%= delimited(@count) %> more <%= if @count == 1, do: @one, else: @many %></p>
    <% end %>
    """
  end

  # One labeled bar, its length a share of `max`.
  attr :label, :any, required: true
  attr :value, :any, required: true
  attr :max, :any, required: true
  attr :note, :string, default: nil
  slot :inner_block
  def bar_row(assigns) do
    width = if is_number(assigns.value) and is_number(assigns.max) and assigns.max > 0, do: min(100, round(assigns.value / assigns.max * 100)), else: 0
    assigns = assign(assigns, :width, width)

    ~H"""
    <div class="bar-row grid grid-cols-[9rem_1fr_6rem] md:grid-cols-[7rem_1fr_5rem] items-center gap-3 py-1.5">
      <span class="text-sm text-gray-700 truncate"><%= if @inner_block != [], do: render_slot(@inner_block), else: @label %></span>
      <div class="bg-gray-100 rounded-full h-3">
        <div class="bg-green h-3 rounded-full" style={"width: #{@width}%"}></div>
      </div>
      <span class="text-sm text-right tabular-nums text-gray-900">
        <%= Helpers.cash(@value) %><%= if @note do %><span class="block text-xs text-gray-500"><%= @note %></span><% end %>
      </span>
    </div>
    """
  end

  defp delimited(n), do: Number.Delimit.number_to_delimited(n, precision: 0)
end
