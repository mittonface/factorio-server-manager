"use client";
import { useState, useEffect } from "react";
import { Sparkles, Zap, Coffee, Cloud, Skull } from "lucide-react";

export default function Home() {
  const [status, setStatus] = useState("stopped");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [bounce, setBounce] = useState(false);

  const handleAction = async (action: "start" | "stop") => {
    setBounce(true);
    setTimeout(() => setBounce(false), 1000);
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

    checkStatus();

    const interval = setInterval(() => {
      if (status === "working") {
        checkStatus();
      }
    }, 10000);

    return () => clearInterval(interval);
  }, [status]);

  const getStatusIcon = () => {
    switch (status) {
      case "running":
        return <Zap className="animate-pulse text-yellow-400" size={24} />;
      case "working":
        return <Coffee className="animate-bounce text-brown-600" size={24} />;
      default:
        return <Skull className="animate-spin-slow text-red-600" size={24} />;
    }
  };

  const funnyStatusMessages = {
    running: "The server is currently online. 🏭.",
    working: "Don't hit any buttons, something is happening. ⚠️",
    stopped: "The server is currently offline. 😴",
  };

  return (
    <main className="min-h-screen p-8 bg-gradient-to-br from-purple-100 via-pink-100 to-blue-100">
      <div
        className={`max-w-md mx-auto bg-white p-6 rounded-lg shadow-lg border-4 border-dashed border-purple-300 transform transition-transform duration-300 ${
          bounce ? "scale-105" : "scale-100"
        }`}
      >
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 text-transparent bg-clip-text">
            Factorio Server for Cool Hot Boys
          </h1>
          <Sparkles className="text-yellow-400 animate-pulse" />
        </div>

        <div className="mb-4 flex items-center gap-2 p-3 bg-gradient-to-r from-purple-50 to-pink-50 rounded-lg">
          {getStatusIcon()}
          <span className="capitalize text-gray-900 font-medium">
            {funnyStatusMessages[status as keyof typeof funnyStatusMessages]}
          </span>
        </div>

        <div className="mb-4 p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg border-2 border-dotted border-blue-200 transform hover:scale-102 transition-transform">
          <h2 className="text-lg font-semibold text-gray-800 mb-2 flex items-center gap-2">
            <Cloud className="text-blue-400" />
            How to Connect
          </h2>
          <p className="text-gray-700 mb-2">
            Look for &quot;Bunch of Nerds&quot; in the Factorio public game
            browser. Use the same password as below.
          </p>
          <p className="text-gray-700 italic animate-pulse">
            It will take a 2-3 minutes for the server to get up and running.
          </p>
        </div>

        <div className="mb-4 relative">
          <label
            htmlFor="password"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            Password
          </label>
          <input
            id="password"
            type="password"
            placeholder="🤫 Super secret"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full p-2 border-2 border-dashed border-purple-200 text-gray-900 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-all"
          />
        </div>

        <div className="flex gap-2 mb-4">
          <button
            onClick={() => handleAction("start")}
            disabled={loading || status === "running" || status === "working"}
            className={`flex-1 py-2 px-4 rounded-lg font-medium focus:ring-2 focus:ring-offset-2 transition-all duration-300 transform hover:scale-105
              ${
                loading || status === "running" || status === "working"
                  ? "bg-gray-400 text-gray-100 cursor-not-allowed"
                  : "bg-gradient-to-r from-green-400 to-blue-500 text-white hover:from-green-500 hover:to-blue-600 focus:ring-blue-500"
              }`}
          >
            🚀 Start Server
          </button>
          <button
            onClick={() => handleAction("stop")}
            disabled={loading || status === "stopped" || status === "working"}
            className={`flex-1 py-2 px-4 rounded-lg font-medium focus:ring-2 focus:ring-offset-2 transition-all duration-300 transform hover:scale-105
              ${
                loading || status === "stopped" || status === "working"
                  ? "bg-gray-400 text-gray-100 cursor-not-allowed"
                  : "bg-gradient-to-r from-red-400 to-pink-500 text-white hover:from-red-500 hover:to-pink-600 focus:ring-red-500"
              }`}
          >
            💤 Stop Server
          </button>
        </div>

        {message && (
          <div
            className={`p-4 rounded-lg border-2 transform transition-all duration-300 ${
              message.includes("error") || message.includes("failed")
                ? "bg-red-50 text-red-800 border-red-200 animate-shake"
                : "bg-blue-50 text-blue-800 border-blue-200 animate-bounce-gentle"
            }`}
            role="alert"
          >
            {message.includes("error") || message.includes("failed")
              ? "🚨 "
              : "✨ "}
            {message}
          </div>
        )}
      </div>
    </main>
  );
}
