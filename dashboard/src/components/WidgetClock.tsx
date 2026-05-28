"use client";

import { useEffect, useState } from "react";

export default function WidgetClock() {
  const [time, setTime] = useState<Date | null>(null);

  useEffect(() => {
    setTime(new Date());
    const id = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  if (!time) return null;

  const timeStr = time.toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
  const dateStr = time.toLocaleDateString([], {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="text-center">
      <p className="text-7xl font-thin text-white tracking-tight tabular-nums">
        {timeStr}
      </p>
      <p className="mt-1 text-white/50 text-lg font-light">{dateStr}</p>
    </div>
  );
}
