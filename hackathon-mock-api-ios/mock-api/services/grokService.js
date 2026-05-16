const GROK_API_URL = "https://api.x.ai/v1/chat/completions";
const GROK_MODEL = "grok-3-mini";

/**
 * Build the recommendation prompt from registry context + product inventory.
 * @param {Object} registry  - Mongoose Registry document (lean or full)
 * @param {Array}  products  - Array of product objects from the /skus endpoint
 * @returns {string} Formatted prompt string
 */
function buildPrompt(registry, products) {
  const isEvent = registry.registryType === "event";
  const plannerAnswers = isEvent
    ? registry.eventDetails?.aiPlannerAnswers ?? []
    : registry.giftingDetails?.aiPlannerAnswers ?? [];
  const budget = isEvent
    ? registry.eventDetails?.targetBudget ?? 0
    : registry.giftingDetails?.creatorBudget ?? registry.giftingDetails?.pooledBudget ?? 0;
  const currencySymbol = registry.currency?.symbol ?? "$";

  const inventoryList = products.map((p) => ({
    id: p._id || p.id,
    name: p.name || p.title,
    price: p.price,
    category: p.category,
    description: p.description,
  }));

  return `You are a gift and event product recommendation engine. Return ONLY a valid JSON array — no markdown, no explanation.

Event context:
- Event type: ${registry.eventType}
- Occasion: ${registry.name}
- Date: ${registry.eventDate ? new Date(registry.eventDate).toDateString() : "Not specified"}
- Budget: ${currencySymbol}${budget}
- User answers: ${JSON.stringify(plannerAnswers)}

Available products (inventory):
${JSON.stringify(inventoryList)}

Return top 8 product recommendations as:
[{"productId": "...", "score": 0.0-1.0, "reasoning": "max 12 words explaining why"}]

Rules:
- Only recommend products from the provided inventory list
- Score must reflect relevance to the event context and budget fit
- reasoning must be ≤12 words, specific, not generic`;
}

/**
 * Parse and validate Grok's JSON response.
 * @param {string} content - Raw text from Grok
 * @returns {Array} Array of {productId, score, reasoning}
 */
function parseGrokResponse(content) {
  // Strip markdown code fences if present
  const cleaned = content
    .replace(/```json\s*/gi, "")
    .replace(/```\s*/g, "")
    .trim();

  const parsed = JSON.parse(cleaned);

  if (!Array.isArray(parsed)) {
    throw new Error("Grok response is not an array");
  }

  return parsed
    .filter(
      (item) =>
        typeof item.productId === "string" &&
        typeof item.score === "number" &&
        typeof item.reasoning === "string"
    )
    .map((item) => ({
      productId: item.productId,
      score: Math.min(1, Math.max(0, item.score)),
      reasoning: item.reasoning.slice(0, 80), // safety cap
      generatedAt: new Date(),
    }))
    .slice(0, 8);
}

/**
 * Call xAI Grok API and return top-8 product suggestions.
 * Falls back to mock suggestions if API key is missing or call fails.
 *
 * @param {Object} registry  - Registry document
 * @param {Array}  products  - Product inventory
 * @returns {Array} Array of {productId, score, reasoning, generatedAt}
 */
async function getGrokSuggestions(registry, products) {
  const apiKey = process.env.GROK_API_KEY;

  if (!apiKey) {
    console.warn("⚠️  GROK_API_KEY not set — returning mock AI suggestions");
    return mockSuggestions(products);
  }

  const prompt = buildPrompt(registry, products);

  const response = await fetch(GROK_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: GROK_MODEL,
      messages: [{ role: "user", content: prompt }],
      temperature: 0.3,
      max_tokens: 1024,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Grok API error ${response.status}: ${errText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;

  if (!content) {
    throw new Error("Empty Grok response");
  }

  return parseGrokResponse(content);
}

/**
 * Mock suggestions used when no API key is configured.
 */
function mockSuggestions(products) {
  return products.slice(0, 8).map((p, i) => ({
    productId: String(p._id || p.id),
    score: parseFloat((0.95 - i * 0.05).toFixed(2)),
    reasoning: "Highly relevant to your event context and budget.",
    generatedAt: new Date(),
  }));
}

module.exports = { getGrokSuggestions };
