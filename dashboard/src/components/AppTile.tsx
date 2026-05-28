export default function AppTile({
  name,
  icon,
  href,
}: {
  name: string;
  icon: string;
  href: string;
}) {
  return (
    <a href={href} className="flex flex-col items-center gap-2 group">
      <div className="w-16 h-16 rounded-2xl bg-white/10 hover:bg-white/20 border border-white/10 flex items-center justify-center text-3xl transition-all duration-150 group-hover:scale-105 shadow-lg">
        {icon}
      </div>
      <span className="text-white/70 text-xs text-center leading-tight group-hover:text-white transition-colors">
        {name}
      </span>
    </a>
  );
}
