import AppTile from "./AppTile";

const APPS = [
  { name: "File Storage", icon: "📁", href: "http://files.astralcloud.local" },
  { name: "Media", icon: "🎬", href: "http://media.astralcloud.local" },
  { name: "Settings", icon: "⚙️", href: "#" },
  { name: "Marketplace", icon: "🛍️", href: "#" },
];

export default function AppGrid() {
  return (
    <section>
      <h2 className="text-white/50 text-xs font-medium uppercase tracking-widest mb-4">
        Apps
      </h2>
      <div className="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-4">
        {APPS.map((app) => (
          <AppTile
            key={app.name}
            name={app.name}
            icon={app.icon}
            href={app.href}
          />
        ))}
      </div>
    </section>
  );
}
