// Financial Advisor edge function.
//
// Proxies chat requests to the Groq API so the GROQ_API_KEY secret never
// reaches the browser. Requires a signed-in Supabase user — the client's JWT
// is verified before any tokens are spent.
//
// Setup:
//   1. Get a free API key at https://console.groq.com/keys
//   2. Supabase Dashboard -> Edge Functions -> Secrets -> add GROQ_API_KEY
//   3. Deploy this function as "financial-advisor"

import { createClient } from "npm:@supabase/supabase-js@2";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "llama-3.3-70b-versatile";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SYSTEM_PROMPT = `You are the in-app financial consultant for a personal finance tracker. You advise the user on purchase timing, loans, and investments using their real financial data (provided below as JSON).

Rules:
- Base every judgement on the user's actual numbers: income, budgets, category spending, savings goals, recurring bills, monthly history, and health score. Cite the specific numbers that drive your conclusion.
- If information needed for a sound recommendation is missing (price, loan amount, interest rate, tenure, expected return, timeline), ask for it in a short follow-up question before concluding. Ask only for what you truly need, at most 2-3 questions at a time.
- Think about the full picture: liquidity after the purchase, emergency buffer (months of expenses covered by savings), impact on savings goals, upcoming recurring bills, and for assets: depreciation (electronics lose roughly 20-30% of value per year), resale value, and opportunity cost versus investing the money.
- For loans: compute the EMI/monthly payment when rate and tenure are known, evaluate the payment against monthly net savings, and flag debt-to-income concerns above ~35%.
- For investments: consider the emergency buffer first, the user's goal timelines, and give balanced, risk-aware guidance. You are not a licensed advisor; keep recommendations educational.
- Currency: use the currency symbol given in the snapshot.
- Keep prose answers concise and structured. Plain text only - no markdown headers or tables.

When (and only when) you deliver a final recommendation on a purchase/loan/investment decision, append a machine-readable report at the very end of the message, wrapped exactly in <impact> and </impact> tags, as strict JSON with this shape:
{
  "verdict": "go" | "wait" | "avoid",
  "title": "<short decision title>",
  "summary": "<one-sentence outcome>",
  "one_time_cost": <number or null>,
  "monthly_cost": <number or null>,
  "current": {"net_savings": <n>, "budget_used_pct": <n>, "buffer_months": <n>, "health_score": <0-100>},
  "projected": {"net_savings": <n>, "budget_used_pct": <n>, "buffer_months": <n>, "health_score": <0-100>},
  "timeline": [{"label": "<Month name>", "without": <cumulative savings without the decision>, "with": <cumulative savings with it>}, ... 6 entries],
  "suggestions": ["<actionable suggestion>", ...]
}
"current" is their financial life today; "projected" is life after the decision. Numbers must be consistent with the snapshot. Do not mention the tags or the JSON in your prose.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Not signed in" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { messages, snapshot } = await req.json();
    if (!Array.isArray(messages) || messages.length === 0) {
      return new Response(JSON.stringify({ error: "messages required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) {
      return new Response(
        JSON.stringify({ error: "GROQ_API_KEY secret not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const groqRes = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.4,
        max_tokens: 1600,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          {
            role: "system",
            content: `User financial snapshot (JSON):\n${
              JSON.stringify(snapshot ?? {})
            }`,
          },
          // Keep the conversation bounded so free-tier token limits hold.
          ...messages.slice(-20),
        ],
      }),
    });

    if (!groqRes.ok) {
      const detail = await groqRes.text();
      const status = groqRes.status === 429 ? 429 : 502;
      return new Response(
        JSON.stringify({
          error: status === 429
            ? "The advisor is rate-limited right now - try again in a minute."
            : "Advisor backend error",
          detail,
        }),
        {
          status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const data = await groqRes.json();
    const content: string = data?.choices?.[0]?.message?.content ?? "";
    return new Response(JSON.stringify({ content }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
