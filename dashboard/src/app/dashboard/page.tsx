import AppGrid from "@/components/AppGrid";
import WidgetClock from "@/components/WidgetClock";
import UserMenu from "@/components/UserMenu";

export default async function DashboardPage() {
  let user: { name?: string | null; email?: string | null } | null = null;

  if (process.env.NODE_ENV === "development") {
    user = { name: "Ananthu PM", email: "ananthu@astralcloud.local" };
  } else {
    const { auth } = await import("@/lib/auth");
    const session = await auth();
    user = session?.user ?? null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top bar */}
      <header className="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-lg bg-indigo-600 flex items-center justify-center">
            <svg
              className="w-4 h-4 text-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"
              />
            </svg>
          </div>
          <span className="font-semibold text-gray-900 text-sm">
            AstralCloud
          </span>
        </div>

        <UserMenu name={user?.name ?? "User"} email={user?.email ?? ""} />
      </header>

      {/* Main content */}
      <main className="max-w-4xl mx-auto px-6 py-10">
        <div className="mb-10">
          <WidgetClock />
        </div>
        <AppGrid />
      </main>
    </div>
  );
}
