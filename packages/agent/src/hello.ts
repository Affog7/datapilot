import Anthropic from "@anthropic-ai/sdk";
import { requireEnv } from "./env.js";

const client = new Anthropic({ apiKey: requireEnv("ANTHROPIC_API_KEY") });

const response = await client.messages.create({
  model: requireEnv("ANTHROPIC_MODEL"),
  max_tokens: 20,
  system: "Tu es DataPilot, un assistant d'analyse e-commerce, et qu'il répond en français en 2 phrases.",
  messages: [
    {
      role: "user",
      content: "Bonjour, comment tu t'appelles ?"
    }
  ]
});

// À TOI 3 : response.content est une LISTE de blocs. Garde ceux dont type === "text",
//           extrais leur .text, et affiche le résultat.

console.log(
  `Modèle : ${response.model} · entrée : ${response.usage.input_tokens} tokens · sortie : ${response.usage.output_tokens} tokens · arrêt : ${response.stop_reason}`,
);


console.log(
  "Réponse :",
  response.content.filter((block) => block.type === "text").map((block) => block.text).join(" ")
);