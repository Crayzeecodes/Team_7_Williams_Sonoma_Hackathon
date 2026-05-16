const XAI_URL = "https://api.x.ai/v1/chat/completions";

function buildPrompt(registry, products) {
  const budget =
    registry.registryType === "event"
      ? registry.eventDetails?.targetBudget ?? 0
      : registry.giftingDetails?.splitType === "dutch"
        ? registry.giftingDetails?.pooledBudget ?? 0
        : registry.giftingDetails?.creatorBudget ?? 0;

  const aiPlannerAnswers =
    registry.registryType === "event"
      ? registry.eventDetails?.aiPlannerAnswers ?? []
      : registry.giftingDetails?.aiPlannerAnswers ?? [];

  return `
You are a gift and event product recommendation engine. Return ONLY a valid JSON array — no markdown, no explanation.

Event context:
- Event type: ${registry.eventType}
- Occasion: ${registry.name}
- Date: ${registry.eventDate instanceof Date ? registry.eventDate.toISOString() : registry.eventDate}
- Budget: ${registry.currency?.symbol || "$"}${budget}
- User answers: ${JSON.stringify(aiPlannerAnswers)}

Available products (inventory):
${JSON.stringify(
    products.map((p) => ({
      id: String(p._id),
      name: p.name,
      price: p.price,
      category: p.category,
      description: p.description,
    }))
  )}

Return top 8 product recommendations as:
[{"productId": "...", "score": 0.0-1.0, "reasoning": "max 12 words explaining why"}]

Rules:
- Only recommend products from the provided inventory list
- Score must reflect relevance to the event context and budget fit
- reasoning must be ≤12 words, specific, not generic
`.trim();
}

function normalizeSuggestions(rawSuggestions, products) {
  const allowedIds = new Set(products.map((product) => String(product._id)));

  return rawSuggestions
    .filter((item) => item && allowedIds.has(String(item.productId)))
    .map((item) => ({
      productId: String(item.productId),
      score: Math.max(0, Math.min(1, Number(item.score) || 0)),
      reasoning: String(item.reasoning || "")
        .trim()
        .split(/\s+/)
        .slice(0, 12)
        .join(" "),
      generatedAt: new Date(),
    }))
    .slice(0, 8);
}

function fallbackSuggestions(registry, products) {
  const budget =
    registry.registryType === "event"
      ? registry.eventDetails?.targetBudget ?? 0
      : registry.giftingDetails?.splitType === "dutch"
        ? registry.giftingDetails?.pooledBudget ?? 0
        : registry.giftingDetails?.creatorBudget ?? 0;

  const plannerText = JSON.stringify(
    registry.registryType === "event"
      ? registry.eventDetails?.aiPlannerAnswers ?? []
      : registry.giftingDetails?.aiPlannerAnswers ?? []
  ).toLowerCase();

  return products
    .map((product) => {
      const categoryHit = plannerText.includes(String(product.category).toLowerCase()) ? 0.25 : 0;
      const eventHit = plannerText.includes(registry.eventType.replace("_", " ")) ? 0.15 : 0;
      const budgetFit = budget > 0 ? Math.max(0, 1 - Math.abs(product.price - budget / 4) / Math.max(budget, 1)) : 0.4;
      const score = Math.max(0, Math.min(1, 0.25 + categoryHit + eventHit + budgetFit * 0.6));

      return {
        productId: String(product._id),
        score,
        reasoning: `${product.category} fit for ${registry.eventType.replace("_", " ")}`.split(/\s+/).slice(0, 12).join(" "),
        generatedAt: new Date(),
      };
    })
    .sort((left, right) => right.score - left.score)
    .slice(0, 8);
}

async function fetchGrokSuggestions(registry, products) {
  const apiKey = process.env.XAI_API_KEY;
  if (!apiKey) {
    return fallbackSuggestions(registry, products);
  }

  const response = await fetch(XAI_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "grok-3-mini",
      temperature: 0.2,
      messages: [
        {
          role: "user",
          content: buildPrompt(registry, products),
        },
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`xAI request failed with ${response.status}`);
  }

  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  const parsed = JSON.parse(content);
  return normalizeSuggestions(Array.isArray(parsed) ? parsed : [], products);
}

module.exports = {
  fetchGrokSuggestions,
};
