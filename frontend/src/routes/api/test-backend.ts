import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/test-backend")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        try {
          const { backend_url } = (await request.json()) as { backend_url?: string };

          if (!backend_url || !backend_url.trim()) {
            return new Response(
              JSON.stringify({ ok: false, error: "Jac backend URL is missing." }),
              { status: 400, headers: { "Content-Type": "application/json" } },
            );
          }

          const base = backend_url.trim().replace(/\/$/, "");
          const url = `${base}/function/debug_env`;
          const upstream = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: "{}",
          });
          const body = await upstream.text();

          return new Response(
            JSON.stringify({ ok: upstream.ok, status: upstream.status, url, body }),
            { status: 200, headers: { "Content-Type": "application/json" } },
          );
        } catch (err) {
          const message = err instanceof Error ? err.message : "Proxy error";
          return new Response(
            JSON.stringify({ ok: false, error: message }),
            { status: 502, headers: { "Content-Type": "application/json" } },
          );
        }
      },
    },
  },
});
