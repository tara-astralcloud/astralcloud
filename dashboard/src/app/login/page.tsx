import { signIn } from "@/lib/auth";

export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900">
      <div className="text-center">
        <div className="mb-8">
          <div className="w-20 h-20 mx-auto mb-4 rounded-3xl bg-blue-500/20 border border-blue-400/30 flex items-center justify-center">
            <svg
              className="w-10 h-10 text-blue-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"
              />
            </svg>
          </div>
          <h1 className="text-3xl font-semibold text-white tracking-tight">
            AstralCloud
          </h1>
          <p className="mt-2 text-blue-300/70 text-sm">Your personal cloud</p>
        </div>
        <form
          action={async () => {
            "use server";
            await signIn("keycloak", { redirectTo: "/dashboard" });
          }}
        >
          <button
            type="submit"
            className="px-8 py-3 rounded-2xl bg-blue-500 hover:bg-blue-400 text-white font-medium text-sm transition-colors duration-150 shadow-lg shadow-blue-500/25"
          >
            Sign in with AstralCloud
          </button>
        </form>
      </div>
    </div>
  );
}
