import Anthropic from "@anthropic-ai/sdk";
import { requireEnv } from "./env.js";

const client = new Anthropic({ apiKey: requireEnv("ANTHROPIC_API_KEY") });

const response = await client.messages.create({
  model: requireEnv("ANTHROPIC_MODEL"),
  // Plafond, pas un coût : seuls les tokens générés sont facturés. Haiku 5.5 réfléchit
  // avant de répondre, et cette réflexion compte dans max_tokens : trop bas, la réponse est coupée.
  max_tokens: 16000,
  system:
    "Tu es DataPilot, un assistant d'analyse e-commerce, et qu'il répond en français en 2 phrases.",
  messages: [
    {
      role: "user",
      content: "Bonjour, comment tu t'appelles ?",
    },
  ],
});

console.log(
  `Modèle : ${response.model} · entrée : ${response.usage.input_tokens} tokens · sortie : ${response.usage.output_tokens} tokens · arrêt : ${response.stop_reason}`,
);

// response.content est une liste de blocs : on ne garde que le texte.
console.log(
  "Réponse :",
  response.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join(" "),
);
