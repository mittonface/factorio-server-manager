"use client";
import { useState, useEffect } from "react";

export default function Home() {
  const [status, setStatus] = useState("stopped");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const handleAction = async (action: "start" | "stop") => {
    setLoading(true);
    setMessage("");
    try {
      const response = await fetch(`/api/${action}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ password }),
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to perform action");
      }
      setMessage(data.message);
      setStatus(action === "start" ? "running" : "stopped");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "An error occurred");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const checkStatus = () => {
      fetch("/api/status")
        .then((res) => res.json())
        .then((data) => setStatus(data.status))
        .catch((error) => setMessage("Failed to fetch status"));
    };

    // Initial check
    checkStatus();

    // Poll every 10 seconds when status is "working"
    const interval = setInterval(() => {
      if (status === "working") {
        checkStatus();
      }
    }, 10000);

    return () => clearInterval(interval);
  }, [status]);

  const getStatusColor = () => {
    switch (status) {
      case "running":
        return "bg-green-600";
      case "working":
        return "bg-yellow-400";
      default:
        return "bg-red-600";
    }
  };

  return (
    <main className="min-h-screen p-8 bg-gray-100">
      <div className="max-w-md mx-auto bg-white p-6 rounded-lg shadow-lg border border-gray-200">
        <h1 className="text-2xl font-bold mb-4 text-gray-900">
          Factorio Server for Cool Hot Boys
        </h1>
        <div className="mb-4 flex items-center gap-2">
          <div
            className={`w-3 h-3 rounded-full ${getStatusColor()}`}
            aria-hidden="true"
          />
          <span className="capitalize text-gray-900">Status: {status}</span>
        </div>

        {/* New Connection Info Section */}
        <div className="mb-4 p-4 bg-gray-50 rounded-lg border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-800 mb-2">
            How to Connect
          </h2>
          <p className="text-gray-700 mb-2">
            Look for &quot;Bunch of Nerds&quot; in the Factorio public game
            browser to join the server. The password is known to you.
          </p>
          <p className="text-gray-700 italic">
            Note: After clicking &quot;Start Server&quot;, please allow
            approximately 5 minutes for the server to fully start up.
          </p>
        </div>

        <div className="mb-4">
          <label
            htmlFor="password"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            Password
          </label>
          <input
            id="password"
            type="password"
            placeholder="Enter password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full p-2 border border-gray-300 text-gray-900 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div className="flex gap-2 mb-4">
          <button
            onClick={() => handleAction("start")}
            disabled={loading || status === "running" || status === "working"}
            className={`flex-1 py-2 px-4 rounded font-medium focus:ring-2 focus:ring-offset-2
              ${
                loading || status === "running" || status === "working"
                  ? "bg-gray-400 text-gray-100 cursor-not-allowed"
                  : "bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500"
              }`}
          >
            Start Server
          </button>
          <button
            onClick={() => handleAction("stop")}
            disabled={loading || status === "stopped" || status === "working"}
            className={`flex-1 py-2 px-4 rounded font-medium focus:ring-2 focus:ring-offset-2
              ${
                loading || status === "stopped" || status === "working"
                  ? "bg-gray-400 text-gray-100 cursor-not-allowed"
                  : "bg-red-600 text-white hover:bg-red-700 focus:ring-red-500"
              }`}
          >
            Stop Server
          </button>
        </div>
        {message && (
          <div
            className={`p-4 rounded border ${
              message.includes("error") || message.includes("failed")
                ? "bg-red-50 text-red-800 border-red-200"
                : "bg-blue-50 text-blue-800 border-blue-200"
            }`}
            role="alert"
          >
            {message}
          </div>
        )}
      </div>
    </main>
  );
}
