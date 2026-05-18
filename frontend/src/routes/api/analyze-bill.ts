import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/analyze-bill")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        try {
          const { bill_text, backend_url } = (await request.json()) as {
            bill_text?: string;
            backend_url?: string;
          };

          if (!backend_url || !backend_url.trim()) {
            return new Response(
              JSON.stringify({ error: "Jac backend URL is missing." }),
              { status: 400, headers: { "Content-Type": "application/json" } },
            );
          }
          if (!bill_text || !bill_text.trim()) {
            return new Response(
              JSON.stringify({ error: "bill_text is required." }),
              { status: 400, headers: { "Content-Type": "application/json" } },
            );
          }

          const base = backend_url.trim().replace(/\/$/, "");
          const upstream = await fetch(`${base}/function/analyze_bill`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ bill_text }),
          });
          const text = await upstream.text();

          if (!upstream.ok) {
            return new Response(
              JSON.stringify({
                error: `Backend error ${upstream.status}: ${text || upstream.statusText}`,
                status: upstream.status,
                body: text,
              }),
              { status: 502, headers: { "Content-Type": "application/json" } },
            );
          }

          return new Response(text, {
            status: 200,
            headers: { "Content-Type": "application/json" },
          });
        } catch (err) {
          const message = err instanceof Error ? err.message : "Proxy error";
          return new Response(JSON.stringify({ error: message }), {
            status: 502,
            headers: { "Content-Type": "application/json" },
          });
        }
      },
    },
  },
});
