"use client";

import { useEffect } from "react";
import { keycloakSignIn } from "./actions";

export default function LoginPage() {
  useEffect(() => {
    if (process.env.NODE_ENV === "development") {
      globalThis.location.href = "/dashboard";
    }
  }, []);

  if (process.env.NODE_ENV === "development") {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <div className="mb-8">
          <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-indigo-600 flex items-center justify-center">
            <svg
              className="w-8 h-8 text-white"
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
          <h1 className="text-2xl font-semibold text-gray-900">AstralCloud</h1>
          <p className="mt-1 text-sm text-gray-500">Your personal cloud</p>
        </div>
        <form action={keycloakSignIn}>
          <button
            type="submit"
            className="px-6 py-2.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium transition-colors shadow-sm"
          >
            Sign in with AstralCloud
          </button>
        </form>
      </div>
    </div>
  );
}
