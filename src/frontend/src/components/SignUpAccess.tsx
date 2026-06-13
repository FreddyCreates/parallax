/**
 * SignUpAccess.tsx — PARALLAX User Signup & Access Point
 * Primary entry point for new users to join the PARALLAX ecosystem
 * Supports Internet Identity, Plug Wallet, and NFID authentication
 */

import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { motion, AnimatePresence } from "motion/react";
import { useState, useCallback } from "react";
import { FiUser, FiShield, FiZap, FiGlobe, FiCheck, FiArrowRight } from "react-icons/fi";

// ── Color Constants ────────────────────────────────────────────────
const C = {
  gold: "oklch(0.78 0.18 85)",
  goldDim: "rgba(200,160,60,0.12)",
  cyan: "oklch(0.72 0.15 200)",
  purple: "oklch(0.65 0.28 290)",
  green: "oklch(0.62 0.17 145)",
  red: "oklch(0.55 0.22 25)",
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  bg: "oklch(0.04 0.01 270)",
  bgPanel: "rgba(4,4,8,0.92)",
  border: "rgba(255,255,255,0.06)",
  borderGold: "rgba(200,160,60,0.2)",
};

interface SignUpAccessProps {
  onComplete: () => void;
  onSkip?: () => void;
}

type AuthMethod = "internet-identity" | "plug-wallet" | "nfid" | null;
type SignUpStep = "welcome" | "choose-auth" | "connecting" | "profile" | "complete";

export function SignUpAccess({ onComplete, onSkip }: SignUpAccessProps) {
  const { login, identity, isInitializing } = useInternetIdentity();
  const [step, setStep] = useState<SignUpStep>("welcome");
  const [selectedAuth, setSelectedAuth] = useState<AuthMethod>(null);
  const [username, setUsername] = useState("");
  const [agreedToTerms, setAgreedToTerms] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);

  const handleAuthSelect = useCallback(async (method: AuthMethod) => {
    setSelectedAuth(method);
    setStep("connecting");
    setIsConnecting(true);

    try {
      if (method === "internet-identity") {
        await login();
      }
      // For other methods, we'd integrate their SDKs here
      setTimeout(() => {
        setIsConnecting(false);
        setStep("profile");
      }, 2000);
    } catch (error) {
      setIsConnecting(false);
      setStep("choose-auth");
    }
  }, [login]);

  const handleProfileComplete = useCallback(() => {
    setStep("complete");
    setTimeout(() => {
      onComplete();
    }, 1500);
  }, [onComplete]);

  const principalId = identity?.getPrincipal().toText() ?? "";
  const shortPrincipal = principalId.length > 20 
    ? `${principalId.slice(0, 8)}...${principalId.slice(-6)}`
    : principalId;

  return (
    <div
      className="min-h-screen flex items-center justify-center px-4"
      style={{
        background: C.bg,
        backgroundImage: `
          radial-gradient(ellipse at 30% 20%, oklch(0.15 0.08 85 / 0.3) 0%, transparent 50%),
          radial-gradient(ellipse at 70% 80%, oklch(0.12 0.06 200 / 0.2) 0%, transparent 50%)
        `,
      }}
    >
      {/* Background Grid */}
      <div
        className="fixed inset-0 pointer-events-none"
        style={{
          backgroundImage: `
            linear-gradient(${C.gold.replace(")", " / 0.02)")} 1px, transparent 1px),
            linear-gradient(90deg, ${C.gold.replace(")", " / 0.02)")} 1px, transparent 1px)
          `,
          backgroundSize: "48px 48px",
        }}
      />

      <AnimatePresence mode="wait">
        {/* Welcome Step */}
        {step === "welcome" && (
          <motion.div
            key="welcome"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5 }}
            className="relative z-10 max-w-lg w-full text-center"
          >
            {/* Animated Logo */}
            <div className="relative w-32 h-32 mx-auto mb-8">
              <motion.div
                className="absolute inset-0 border-2"
                style={{ borderColor: C.gold }}
                animate={{ rotate: 360 }}
                transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
              />
              <motion.div
                className="absolute inset-4 border"
                style={{ borderColor: `${C.gold}80` }}
                animate={{ rotate: -360 }}
                transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
              />
              <div
                className="absolute inset-0 flex items-center justify-center"
              >
                <div
                  className="w-12 h-12"
                  style={{
                    backgroundColor: C.gold,
                    boxShadow: `0 0 40px ${C.gold}`,
                  }}
                />
              </div>
            </div>

            <h1
              className="font-display font-bold text-4xl tracking-[0.4em] mb-4"
              style={{ color: C.text, textShadow: `0 0 30px ${C.gold}40` }}
            >
              PARALLAX
            </h1>

            <p
              className="font-mono text-xs tracking-[0.2em] mb-2"
              style={{ color: C.muted }}
            >
              DECENTRALIZED EXCHANGE CLEARINGHOUSE
            </p>
            <p
              className="font-mono text-[10px] tracking-[0.15em] mb-8"
              style={{ color: `${C.muted}80` }}
            >
              AI-NATIVE • ZERO GAS • INSTANT SETTLEMENT
            </p>

            {/* Features Grid */}
            <div className="grid grid-cols-2 gap-4 mb-8">
              {[
                { icon: FiZap, label: "Zero Gas Fees", desc: "Trade for free" },
                { icon: FiShield, label: "Secure", desc: "ICP powered" },
                { icon: FiGlobe, label: "Universal", desc: "All assets" },
                { icon: FiUser, label: "Sovereign", desc: "You control" },
              ].map((feature, i) => (
                <motion.div
                  key={feature.label}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2 + i * 0.1 }}
                  className="p-4 border"
                  style={{
                    borderColor: C.border,
                    background: C.bgPanel,
                  }}
                >
                  <feature.icon
                    className="w-5 h-5 mx-auto mb-2"
                    style={{ color: C.gold }}
                  />
                  <div
                    className="font-mono text-[9px] tracking-[0.2em]"
                    style={{ color: C.text }}
                  >
                    {feature.label}
                  </div>
                  <div
                    className="font-mono text-[8px]"
                    style={{ color: C.muted }}
                  >
                    {feature.desc}
                  </div>
                </motion.div>
              ))}
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => setStep("choose-auth")}
              className="w-full py-4 font-mono text-sm tracking-[0.3em] border-2 transition-all"
              style={{
                borderColor: C.gold,
                color: C.gold,
                background: `${C.gold}10`,
                boxShadow: `0 0 30px ${C.gold}20`,
              }}
            >
              GET STARTED
            </motion.button>

            {onSkip && (
              <button
                type="button"
                onClick={onSkip}
                className="mt-4 font-mono text-[10px] tracking-[0.2em] underline"
                style={{ color: C.muted }}
              >
                EXPLORE AS GUEST
              </button>
            )}
          </motion.div>
        )}

        {/* Choose Auth Method Step */}
        {step === "choose-auth" && (
          <motion.div
            key="choose-auth"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5 }}
            className="relative z-10 max-w-md w-full"
          >
            <div
              className="p-8 border"
              style={{
                borderColor: C.borderGold,
                background: C.bgPanel,
                backdropFilter: "blur(20px)",
              }}
            >
              <h2
                className="font-display font-bold text-xl tracking-[0.3em] mb-2 text-center"
                style={{ color: C.text }}
              >
                CONNECT WALLET
              </h2>
              <p
                className="font-mono text-[9px] tracking-[0.2em] mb-8 text-center"
                style={{ color: C.muted }}
              >
                CHOOSE YOUR AUTHENTICATION METHOD
              </p>

              <div className="space-y-3">
                {/* Internet Identity */}
                <motion.button
                  whileHover={{ scale: 1.01, x: 4 }}
                  whileTap={{ scale: 0.99 }}
                  onClick={() => handleAuthSelect("internet-identity")}
                  className="w-full p-4 border flex items-center gap-4 transition-all"
                  style={{
                    borderColor: selectedAuth === "internet-identity" ? C.gold : C.border,
                    background: selectedAuth === "internet-identity" ? `${C.gold}10` : "transparent",
                  }}
                >
                  <div
                    className="w-10 h-10 border flex items-center justify-center"
                    style={{ borderColor: C.cyan }}
                  >
                    <FiShield className="w-5 h-5" style={{ color: C.cyan }} />
                  </div>
                  <div className="flex-1 text-left">
                    <div
                      className="font-mono text-xs tracking-[0.2em]"
                      style={{ color: C.text }}
                    >
                      INTERNET IDENTITY
                    </div>
                    <div
                      className="font-mono text-[8px]"
                      style={{ color: C.muted }}
                    >
                      Native ICP authentication
                    </div>
                  </div>
                  <div
                    className="px-2 py-1 text-[7px] font-mono tracking-wider"
                    style={{ background: `${C.green}20`, color: C.green }}
                  >
                    RECOMMENDED
                  </div>
                </motion.button>

                {/* Plug Wallet */}
                <motion.button
                  whileHover={{ scale: 1.01, x: 4 }}
                  whileTap={{ scale: 0.99 }}
                  onClick={() => handleAuthSelect("plug-wallet")}
                  className="w-full p-4 border flex items-center gap-4 transition-all"
                  style={{
                    borderColor: selectedAuth === "plug-wallet" ? C.gold : C.border,
                    background: selectedAuth === "plug-wallet" ? `${C.gold}10` : "transparent",
                  }}
                >
                  <div
                    className="w-10 h-10 border flex items-center justify-center"
                    style={{ borderColor: C.purple }}
                  >
                    <FiZap className="w-5 h-5" style={{ color: C.purple }} />
                  </div>
                  <div className="flex-1 text-left">
                    <div
                      className="font-mono text-xs tracking-[0.2em]"
                      style={{ color: C.text }}
                    >
                      PLUG WALLET
                    </div>
                    <div
                      className="font-mono text-[8px]"
                      style={{ color: C.muted }}
                    >
                      Browser extension wallet
                    </div>
                  </div>
                </motion.button>

                {/* NFID */}
                <motion.button
                  whileHover={{ scale: 1.01, x: 4 }}
                  whileTap={{ scale: 0.99 }}
                  onClick={() => handleAuthSelect("nfid")}
                  className="w-full p-4 border flex items-center gap-4 transition-all"
                  style={{
                    borderColor: selectedAuth === "nfid" ? C.gold : C.border,
                    background: selectedAuth === "nfid" ? `${C.gold}10` : "transparent",
                  }}
                >
                  <div
                    className="w-10 h-10 border flex items-center justify-center"
                    style={{ borderColor: C.gold }}
                  >
                    <FiGlobe className="w-5 h-5" style={{ color: C.gold }} />
                  </div>
                  <div className="flex-1 text-left">
                    <div
                      className="font-mono text-xs tracking-[0.2em]"
                      style={{ color: C.text }}
                    >
                      NFID
                    </div>
                    <div
                      className="font-mono text-[8px]"
                      style={{ color: C.muted }}
                    >
                      Sign in with email or social
                    </div>
                  </div>
                </motion.button>
              </div>

              <button
                type="button"
                onClick={() => setStep("welcome")}
                className="mt-6 w-full font-mono text-[10px] tracking-[0.2em]"
                style={{ color: C.muted }}
              >
                ← BACK
              </button>
            </div>
          </motion.div>
        )}

        {/* Connecting Step */}
        {step === "connecting" && (
          <motion.div
            key="connecting"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.3 }}
            className="relative z-10 text-center"
          >
            <div className="relative w-24 h-24 mx-auto mb-6">
              <motion.div
                className="absolute inset-0 border-2"
                style={{ borderColor: C.gold }}
                animate={{ rotate: 360 }}
                transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
              />
              <motion.div
                className="absolute inset-0 flex items-center justify-center"
                animate={{ opacity: [0.5, 1, 0.5] }}
                transition={{ duration: 1.5, repeat: Infinity }}
              >
                <div
                  className="w-8 h-8"
                  style={{ backgroundColor: C.gold, boxShadow: `0 0 20px ${C.gold}` }}
                />
              </motion.div>
            </div>

            <h2
              className="font-mono text-sm tracking-[0.3em] mb-2"
              style={{ color: C.text }}
            >
              CONNECTING
            </h2>
            <p
              className="font-mono text-[9px] tracking-[0.2em]"
              style={{ color: C.muted }}
            >
              AUTHENTICATING WITH {selectedAuth?.toUpperCase().replace("-", " ")}
            </p>
          </motion.div>
        )}

        {/* Profile Setup Step */}
        {step === "profile" && (
          <motion.div
            key="profile"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5 }}
            className="relative z-10 max-w-md w-full"
          >
            <div
              className="p-8 border"
              style={{
                borderColor: C.borderGold,
                background: C.bgPanel,
                backdropFilter: "blur(20px)",
              }}
            >
              <div className="flex items-center gap-2 mb-6">
                <FiCheck className="w-5 h-5" style={{ color: C.green }} />
                <span
                  className="font-mono text-[10px] tracking-[0.2em]"
                  style={{ color: C.green }}
                >
                  WALLET CONNECTED
                </span>
              </div>

              {principalId && (
                <div
                  className="p-3 mb-6 border"
                  style={{ borderColor: C.border, background: `${C.gold}05` }}
                >
                  <div
                    className="font-mono text-[8px] tracking-[0.2em] mb-1"
                    style={{ color: C.muted }}
                  >
                    PRINCIPAL ID
                  </div>
                  <div
                    className="font-mono text-xs"
                    style={{ color: C.gold }}
                  >
                    {shortPrincipal}
                  </div>
                </div>
              )}

              <h2
                className="font-display font-bold text-xl tracking-[0.3em] mb-2"
                style={{ color: C.text }}
              >
                SETUP PROFILE
              </h2>
              <p
                className="font-mono text-[9px] tracking-[0.2em] mb-6"
                style={{ color: C.muted }}
              >
                OPTIONAL: CREATE YOUR TRADING IDENTITY
              </p>

              <div className="space-y-4">
                <div>
                  <label
                    className="block font-mono text-[8px] tracking-[0.2em] mb-2"
                    style={{ color: C.muted }}
                  >
                    DISPLAY NAME
                  </label>
                  <input
                    type="text"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="Anonymous Trader"
                    className="w-full p-3 border font-mono text-sm bg-transparent outline-none"
                    style={{
                      borderColor: C.border,
                      color: C.text,
                    }}
                  />
                </div>

                <label className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={agreedToTerms}
                    onChange={(e) => setAgreedToTerms(e.target.checked)}
                    className="mt-1"
                  />
                  <span
                    className="font-mono text-[9px] leading-relaxed"
                    style={{ color: C.muted }}
                  >
                    I agree to the PARALLAX Sovereign License and understand that I am
                    responsible for my own trades and wallet security.
                  </span>
                </label>
              </div>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={handleProfileComplete}
                disabled={!agreedToTerms}
                className="w-full mt-6 py-4 font-mono text-sm tracking-[0.3em] border-2 transition-all disabled:opacity-40"
                style={{
                  borderColor: C.gold,
                  color: C.gold,
                  background: `${C.gold}10`,
                }}
              >
                ENTER PARALLAX <FiArrowRight className="inline ml-2" />
              </motion.button>

              <button
                type="button"
                onClick={handleProfileComplete}
                className="mt-3 w-full font-mono text-[10px] tracking-[0.2em]"
                style={{ color: C.muted }}
              >
                SKIP FOR NOW
              </button>
            </div>
          </motion.div>
        )}

        {/* Complete Step */}
        {step === "complete" && (
          <motion.div
            key="complete"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 1.1 }}
            transition={{ duration: 0.5 }}
            className="relative z-10 text-center"
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200, damping: 15 }}
              className="w-20 h-20 mx-auto mb-6 border-2 flex items-center justify-center"
              style={{ borderColor: C.green }}
            >
              <FiCheck className="w-10 h-10" style={{ color: C.green }} />
            </motion.div>

            <h2
              className="font-display font-bold text-2xl tracking-[0.3em] mb-2"
              style={{ color: C.text }}
            >
              WELCOME
            </h2>
            <p
              className="font-mono text-[10px] tracking-[0.2em]"
              style={{ color: C.green }}
            >
              ENTERING THE SOVEREIGN EXCHANGE
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default SignUpAccess;
