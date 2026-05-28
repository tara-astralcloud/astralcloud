import { auth } from "@/lib/auth";

export default auth((req) => {
  // Skip auth in development so the UI can be previewed without Keycloak
  if (process.env.NODE_ENV === "development") return;

  const { nextUrl, auth: session } = req;
  const isPublic = ["/login", "/api/auth", "/api/health"].some((p) =>
    nextUrl.pathname.startsWith(p),
  );
  if (isPublic) return;
  if (!session) return Response.redirect(new URL("/login", nextUrl));
});

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
