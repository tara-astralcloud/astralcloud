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
    <div>
      <p className="text-5xl font-light text-gray-900 tabular-nums">
        {timeStr}
      </p>
      <p className="mt-1 text-sm text-gray-400">{dateStr}</p>
    </div>
  );
}
