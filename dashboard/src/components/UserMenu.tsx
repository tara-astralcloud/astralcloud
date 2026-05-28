import { signOut } from "@/lib/auth";

export default function UserMenu({
  name,
  email,
}: {
  name: string;
  email: string;
}) {
  const initials = name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className="flex items-center gap-3">
      <div className="text-right hidden sm:block">
        <p className="text-white text-sm font-medium leading-tight">{name}</p>
        <p className="text-white/40 text-xs">{email}</p>
      </div>
      <div className="relative group">
        <button className="w-9 h-9 rounded-full bg-blue-500/30 border border-blue-400/40 flex items-center justify-center text-blue-200 text-sm font-medium hover:bg-blue-500/50 transition-colors">
          {initials}
        </button>
        <div className="absolute right-0 mt-2 w-40 rounded-2xl bg-slate-800/90 border border-white/10 backdrop-blur-sm shadow-xl overflow-hidden opacity-0 pointer-events-none group-hover:opacity-100 group-hover:pointer-events-auto transition-opacity">
          <form
            action={async () => {
              "use server";
              await signOut({ redirectTo: "/login" });
            }}
          >
            <button
              type="submit"
              className="w-full text-left px-4 py-3 text-sm text-white/70 hover:text-white hover:bg-white/5 transition-colors"
            >
              Sign out
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
