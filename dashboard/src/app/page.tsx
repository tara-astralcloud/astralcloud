import { redirect } from "next/navigation";

export default async function HomePage() {
  // In dev, skip auth entirely — go straight to dashboard for UI preview
  if (process.env.NODE_ENV === "development") redirect("/dashboard");

  const { auth } = await import("@/lib/auth");
  const session = await auth();
  if (session) redirect("/dashboard");
  redirect("/login");
}
