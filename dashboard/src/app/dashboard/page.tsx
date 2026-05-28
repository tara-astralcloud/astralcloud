import { auth } from "@/lib/auth";
import AppGrid from "@/components/AppGrid";
import WidgetClock from "@/components/WidgetClock";
import UserMenu from "@/components/UserMenu";

export default async function DashboardPage() {
  const session = await auth();

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900">
      {/* Top bar */}
      <header className="flex items-center justify-between px-6 py-4">
        <h1 className="text-white font-semibold text-lg tracking-tight">
          AstralCloud
        </h1>
        <UserMenu
          name={session?.user?.name ?? "User"}
          email={session?.user?.email ?? ""}
        />
      </header>

      {/* Main content */}
      <main className="max-w-5xl mx-auto px-6 pb-12">
        {/* Clock widget */}
        <div className="mb-10 mt-4">
          <WidgetClock />
        </div>

        {/* App grid */}
        <AppGrid />
      </main>
    </div>
  );
}
