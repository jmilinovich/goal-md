import React, { CSSProperties } from "react";
import { colors, terminalContainer } from "../styles";

interface TerminalChromeProps {
  width: number;
  children: React.ReactNode;
  style?: CSSProperties;
}

export const TerminalChrome: React.FC<TerminalChromeProps> = ({ width, children, style }) => {
  return (
    <div
      style={{
        ...terminalContainer,
        width,
        ...style,
      }}
    >
      {/* macOS window dots */}
      <div style={{ display: "flex", gap: 8, marginBottom: 18 }}>
        <div style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: colors.red, opacity: 0.8 }} />
        <div style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: colors.amber, opacity: 0.8 }} />
        <div style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: colors.green, opacity: 0.8 }} />
      </div>

      {children}
    </div>
  );
};
