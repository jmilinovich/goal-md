import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { colors, mono, terminalContainer, heading, sans, FRAMES_PER_BEAT, FRAME_PADDING, centeredContent, FONT_SIZES } from "../styles";
import { TerminalChrome } from "../components/TerminalChrome";

export const Scene1Problem: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Gentle fade in
  const titleOpacity = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: "clamp" });
  const titleY = spring({ frame, fps, config: { damping: 24, stiffness: 100, mass: 1 } });

  // Terminal appears
  const termDelay = FRAMES_PER_BEAT * 2;
  const termAppear = spring({
    frame: frame - termDelay,
    fps,
    config: { damping: 20, stiffness: 80, mass: 1.2 },
  });

  // Lines appear gently staggered
  const line1Frame = FRAMES_PER_BEAT * 4;
  const line2Frame = FRAMES_PER_BEAT * 5;
  const line3Frame = FRAMES_PER_BEAT * 6;
  const summaryFrame = FRAMES_PER_BEAT * 8;
  const questionFrame = FRAMES_PER_BEAT * 11;

  const cursorVisible = Math.floor(frame / 18) % 2 === 0;

  const questionSpring = spring({
    frame: frame - questionFrame,
    fps,
    config: { damping: 16, stiffness: 120, mass: 0.8 },
  });

  const lineOpacity = (startFrame: number) =>
    interpolate(frame, [startFrame, startFrame + 8], [0, 1], { extrapolateRight: "clamp" });

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {/* Title — centered with consistent padding */}
      <div
        style={{
          ...centeredContent,
          ...heading,
          fontSize: FONT_SIZES.title,
          opacity: titleOpacity,
          transform: `translateY(${interpolate(titleY, [0, 1], [12, 0])}px)`,
          top: 100,
          textAlign: "center",
        }}
      >
        <span style={{ color: colors.textDim }}>most software doesn't have a </span>
        <span style={{ color: colors.red, fontWeight: 800 }}>loss function</span>
      </div>

      {/* Terminal — centered, consistent width */}
      <div
        style={{
          ...centeredContent,
          top: 200,
          display: "flex",
          justifyContent: "center",
        }}
      >
        <TerminalChrome
          width={680}
          style={{
            opacity: interpolate(termAppear, [0, 1], [0, 1]),
            transform: `translateY(${interpolate(termAppear, [0, 1], [20, 0])}px)`,
          }}
        >
          <div style={{ color: colors.textDim, marginBottom: 14 }}>
            <span style={{ color: colors.blue }}>$</span> npm test
          </div>

          {frame > line1Frame && (
            <div style={{ marginBottom: 4, opacity: lineOpacity(line1Frame) }}>
              <span style={{ color: colors.green, fontWeight: 600 }}>PASS</span>
              <span style={{ color: colors.textDim }}> src/routes/auth.test.ts</span>
            </div>
          )}
          {frame > line2Frame && (
            <div style={{ marginBottom: 4, opacity: lineOpacity(line2Frame) }}>
              <span style={{ color: colors.green, fontWeight: 600 }}>PASS</span>
              <span style={{ color: colors.textDim }}> src/routes/users.test.ts</span>
            </div>
          )}
          {frame > line3Frame && (
            <div style={{ marginBottom: 4, opacity: lineOpacity(line3Frame) }}>
              <span style={{ color: colors.green, fontWeight: 600 }}>PASS</span>
              <span style={{ color: colors.textDim }}> src/routes/orders.test.ts</span>
            </div>
          )}
          {frame > summaryFrame && (
            <div style={{ marginTop: 18, opacity: lineOpacity(summaryFrame) }}>
              <div style={{ color: colors.text }}>
                Tests: <span style={{ color: colors.green, fontWeight: 600 }}>38 passed</span>, 38 total
              </div>
              <div style={{ color: colors.muted, fontSize: FONT_SIZES.label }}>Time: 4.2s</div>
            </div>
          )}

          {frame > summaryFrame + 20 && (
            <div style={{ marginTop: 14 }}>
              <span style={{ color: colors.blue }}>$</span>
              <span
                style={{
                  display: "inline-block",
                  width: 9,
                  height: 20,
                  backgroundColor: cursorVisible ? colors.text : "transparent",
                  marginLeft: 8,
                  verticalAlign: "middle",
                }}
              />
            </div>
          )}
        </TerminalChrome>
      </div>

      {/* Question */}
      {frame > questionFrame && (
        <div
          style={{
            ...centeredContent,
            bottom: 80,
            textAlign: "center",
          }}
        >
          <div
            style={{
              ...heading,
              fontSize: FONT_SIZES.heading,
              opacity: interpolate(questionSpring, [0, 1], [0, 1]),
              transform: `translateY(${interpolate(questionSpring, [0, 1], [10, 0])}px)`,
            }}
          >
            <span style={{ color: colors.textDim }}>tests pass. but is it </span>
            <span style={{ color: colors.blue, fontStyle: "italic" }}>better</span>
            <span style={{ color: colors.textDim }}>?</span>
          </div>
          {/* Lineage hint */}
          <div
            style={{
              ...sans,
              fontSize: FONT_SIZES.caption,
              color: colors.muted,
              marginTop: 10,
              fontWeight: 400,
              opacity: interpolate(frame, [questionFrame + 15, questionFrame + 30], [0, 1], { extrapolateRight: "clamp" }),
            }}
          >
            Karpathy's autoresearch proved: agent + fitness function + loop = breakthroughs
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
