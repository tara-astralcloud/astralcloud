"use server";

export async function keycloakSignIn() {
  const { signIn } = await import("@/lib/auth");
  await signIn("keycloak", { redirectTo: "/dashboard" });
}
