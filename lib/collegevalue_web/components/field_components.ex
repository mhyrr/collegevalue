defmodule CollegevalueWeb.FieldComponents do
  @moduledoc "The field page's computed answer: the verdict and its evidence."
  use Phoenix.Component
  import CollegevalueWeb.DataComponents, only: [bar_row: 1]
  import CollegevalueWeb.Views.Helpers, only: [cash: 1, months: 1, college_page_path: 2]

  # The short answer at the head of "Is a <major> degree worth it?", from
  # `CollegevalueWeb.FieldAnswer.verdict/1`. Nothing when there is no verdict.
  attr :verdict, :map, default: nil

  def field_verdict(%{verdict: nil} = assigns), do: ~H""

  def field_verdict(assigns) do
    ~H"""
    <div class={[
      "field-verdict rounded-lg border-l-4 px-5 py-4",
      @verdict.tone == :good && "border-green bg-lightgreen/10",
      @verdict.tone == :mixed && "border-amber-500 bg-amber-50",
      @verdict.tone == :poor && "border-red-500 bg-red-50"
    ]}>
      <p class="text-xs uppercase tracking-wider text-gray-500">Short answer</p>
      <p class="pt-1 text-2xl font-display text-darkgreen"><%= @verdict.headline %></p>
      <p class="pt-2 text-base leading-relaxed text-gray-700"><%= Enum.join(@verdict.sentences, " ") %></p>
    </div>
    """
  end

  # The evidence behind the verdict: school type, selectivity, four-year cost,
  # parent loans and a nearby pair. Each card shows only with its data.
  attr :answer, :map, required: true
  attr :short_name, :string, required: true

  def field_evidence(assigns) do
    ~H"""
    <section class="field-evidence pt-12">
      <h2 class="text-darkgreen text-2xl font-display">What Decides Whether <%= @short_name %> Pays Off</h2>
      <p class="pt-1 pb-6 text-sm text-gray-500">Bachelor's programs only. Medians across the programs in each group; payback is months of first-year pay to equal the student debt.</p>

      <div class="grid grid-cols-2 lg:grid-cols-1 gap-6">
        <%= if @answer.control != [] do %>
          <div class="evidence-control rounded-lg border border-gray-200 p-6 md:p-4">
            <h3 class="text-darkgreen text-xl font-display">Public, Private or For-Profit</h3>
            <%= if @answer.control_sentence do %><p class="pt-2 text-gray-700 leading-relaxed"><%= @answer.control_sentence %></p><% end %>
            <.group_table rows={@answer.control} label="School type" />
          </div>
        <% end %>

        <%= if @answer.admission != [] do %>
          <div class="evidence-admission rounded-lg border border-gray-200 p-6 md:p-4">
            <h3 class="text-darkgreen text-xl font-display">Does a Selective College Pay More?</h3>
            <%= if @answer.admission_sentence do %><p class="pt-2 text-gray-700 leading-relaxed"><%= @answer.admission_sentence %></p><% end %>
            <.group_table rows={@answer.admission} label="Admission rate" />
          </div>
        <% end %>

        <%= if @answer.cost != [] do %>
          <% max = @answer.cost |> Enum.map(&elem(&1, 1)) |> Enum.max() %>
          <div class="evidence-cost rounded-lg border border-gray-200 p-6 md:p-4">
            <h3 class="text-darkgreen text-xl font-display">What Four Years Cost</h3>
            <p class="pt-1 pb-3 text-sm text-gray-500">Median four-year net price after grants, by family income, at the colleges offering this major.</p>
            <%= for {label, dollars} <- @answer.cost do %>
              <.bar_row label={label} value={dollars} max={max} />
            <% end %>
            <%= if @answer.cost_sentence do %><p class="pt-3 text-gray-700 leading-relaxed"><%= @answer.cost_sentence %></p><% end %>
          </div>
        <% end %>

        <%= if @answer.pair do %>
          <div class="evidence-pair rounded-lg border border-gray-200 p-6 md:p-4">
            <h3 class="text-darkgreen text-xl font-display">Same Pay, Different Debt</h3>
            <p class="pt-2 text-gray-700 leading-relaxed">
              Two programs <%= @answer.pair.miles %> <%= if @answer.pair.miles == 1, do: "mile", else: "miles" %> apart pay their graduates about the same, and one leaves them owing <%= @answer.pair.times %>x as much.
            </p>
            <dl class="grid grid-cols-2 gap-4 pt-4">
              <%= for p <- @answer.pair.programs do %>
                <div class="rounded-md bg-gray-50 p-3 text-sm">
                  <dt class="font-bold">
                    <%= if p.unit_id do %>
                      <a href={college_page_path(p.unit_id, p.college)} class="no-underline text-green hover:underline"><%= p.college %></a>
                    <% else %>
                      <%= p.college %>
                    <% end %>
                    <span class="block text-xs font-normal text-gray-500"><%= p.city %>, <%= p.state %></span>
                  </dt>
                  <dd class="pt-2 tabular-nums">Pay <%= cash(p.earnings) %></dd>
                  <dd class="tabular-nums">Debt <%= cash(p.debt) %></dd>
                  <dd class="tabular-nums text-gray-500"><%= months(p.months_to_repay) %> to repay</dd>
                </div>
              <% end %>
            </dl>
          </div>
        <% end %>

        <%= if @answer.parent_sentence do %>
          <div class="evidence-parent rounded-lg border border-gray-200 p-6 md:p-4">
            <h3 class="text-darkgreen text-xl font-display">Parent Loans</h3>
            <p class="pt-2 text-gray-700 leading-relaxed"><%= @answer.parent_sentence %></p>
            <p class="pt-3 text-sm"><a href="/fields/rank?rank=parent_loans" class="no-underline text-green hover:underline">Majors ranked by what parents owe →</a></p>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  attr :rows, :list, required: true
  attr :label, :string, required: true

  defp group_table(assigns) do
    ~H"""
    <table class="compact-table mt-4 w-full text-sm md:text-xs">
      <thead>
        <tr class="text-left text-xs uppercase tracking-wider text-gray-500">
          <th class="py-2 pr-2 font-normal text-left"><%= @label %></th>
          <th class="py-2 px-2 font-normal text-right md:hidden">Programs</th>
          <th class="py-2 px-2 font-normal text-right">Pay</th>
          <th class="py-2 px-2 font-normal text-right">Debt</th>
          <th class="py-2 pl-2 font-normal text-right">Payback</th>
        </tr>
      </thead>
      <tbody>
        <%= for row <- @rows do %>
          <tr class="border-t border-gray-100">
            <td class="py-2 pr-2"><%= row.label %></td>
            <td class="py-2 px-2 text-right tabular-nums md:hidden"><%= row.programs %></td>
            <td class="py-2 px-2 text-right tabular-nums"><%= cash(row.earnings_median) %></td>
            <td class="py-2 px-2 text-right tabular-nums"><%= cash(row.debt_median) %></td>
            <td class="py-2 pl-2 text-right tabular-nums"><%= months(row.months_to_repay_median) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
