export interface Env {
  GEMINI_API_KEY: string;
  GEMINI_MODEL?: string;
}

type GeminiResponse = {
  candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
};

const jsonHeaders = {
  "content-type": "application/json; charset=UTF-8",
  "cache-control": "no-store"
};

const systemPrompt = `You translate Japanese chat messages into natural conversational English. Preserve the real intended meaning, tone, emotion, slang, implied context, teasing, friendliness, sarcasm, politeness, and casual texting style. Do not translate mechanically word-for-word. Do not invent context. Return ONLY valid JSON with keys naturalEnglish (string) and meaning (string or null). Keep meaning brief and null for simple messages.`;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return Response.json({ error: "Method not allowed." }, { status: 405, headers: jsonHeaders });
    }

    let japanese: string | undefined;
    try {
      ({ japanese } = await request.json<{ japanese?: string }>());
    } catch {
      return Response.json({ error: "Invalid request." }, { status: 400, headers: jsonHeaders });
    }

    const input = japanese?.trim();
    if (!input) return Response.json({ error: "Paste a Japanese message first." }, { status: 400, headers: jsonHeaders });
    if (input.length > 6000) return Response.json({ error: "That message is too long. Please shorten it and try again." }, { status: 413, headers: jsonHeaders });
    if (!/[\u3040-\u30ff\u3400-\u9fff]/.test(input)) return Response.json({ error: "Paste a Japanese message to translate." }, { status: 422, headers: jsonHeaders });

    const model = env.GEMINI_MODEL || "gemini-2.5-flash";
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`, {
      method: "POST",
      headers: { "content-type": "application/json", "x-goog-api-key": env.GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{ parts: [{ text: `${systemPrompt}\n\nJapanese message:\n${input}` }] }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.2 }
      })
    });

    if (response.status === 429) return Response.json({ error: "Nua is busy right now. Please try again in a moment." }, { status: 429, headers: jsonHeaders });
    if (!response.ok) {
      // Keep the provider response out of the app, but retain it in Worker logs so
      // a failed key, disabled API, or unavailable model can be diagnosed safely.
      const providerDetails = await response.text();
      console.error("Gemini generateContent failed", {
        status: response.status,
        model,
        details: providerDetails
      });

      const error = response.status === 401 || response.status === 403
        ? "Nua’s Gemini API key was rejected. Please update the Worker secret."
        : response.status === 404
          ? "Nua’s selected Gemini model is unavailable. Please update GEMINI_MODEL."
          : "Nua’s translation service is unavailable. Please try again.";
      return Response.json({ error }, { status: 502, headers: jsonHeaders });
    }

    const gemini = await response.json<GeminiResponse>();
    const output = gemini.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!output) return Response.json({ error: "No translation was returned. Please try again." }, { status: 502, headers: jsonHeaders });

    try {
      const translation = JSON.parse(output) as { naturalEnglish?: string; meaning?: string | null };
      if (!translation.naturalEnglish) throw new Error("empty translation");
      return Response.json({ naturalEnglish: translation.naturalEnglish, meaning: translation.meaning ?? null }, { headers: jsonHeaders });
    } catch {
      return Response.json({ error: "Nua received an unexpected translation response." }, { status: 502, headers: jsonHeaders });
    }
  }
};
