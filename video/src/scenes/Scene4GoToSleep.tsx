import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { colors, mono, terminalContainer, heading, sans, FRAMES_PER_BEAT, FRAME_PADDING, centeredContent, FONT_SIZES } from "../styles";
import { TerminalChrome } from "../components/TerminalChrome";

const getScoreColor = (s: number) => s >= 75 ? colors.green : s >= 60 ? colors.amber : colors.red;

export const Scene4GoToSleep: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const termSpring = spring({ frame, fps, config: { damping: 20, stiffness: 80 } });

  const clockStart = FRAMES_PER_BEAT * 5;
  const clockOpacity = interpolate(frame, [clockStart, clockStart + 15], [0, 1], { extrapolateRight: "clamp" });
  const hours = Math.floor(interpolate(frame, [clockStart + 15, clockStart + FRAMES_PER_BEAT * 7], [0, 8], { extrapolateRight: "clamp" }));
  const clockTime = `${(11 + hours) % 12 || 12}:${hours > 4 ? "47" : "23"} ${11 + hours >= 12 && 11 + hours < 24 ? "AM" : "PM"}`;

  const resultStart = FRAMES_PER_BEAT * 12;
  const resultSpring = spring({ frame: frame - resultStart, fps, config: { damping: 12, stiffness: 100, mass: 0.8 } });

  const ctaStart = FRAMES_PER_BEAT * 16;
  const ctaSpring = spring({ frame: frame - ctaStart, fps, config: { damping: 18, stiffness: 80 } });

  const dotCount = (Math.floor(frame / 12) % 3) + 1;
  const dots = ".".repeat(dotCount);
  // Dim terminal during clock, fully hide when result appears
  const termDim = frame > resultStart
    ? interpolate(frame, [resultStart, resultStart + 10], [0.12, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })
    : frame > clockStart
      ? interpolate(frame, [clockStart, clockStart + 20], [1, 0.12], { extrapolateRight: "clamp" })
      : 1;

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {/* Terminal */}
      <div style={{ ...centeredContent, top: 140, display: "flex", justifyContent: "center" }}>
        <TerminalChrome
          width={680}
          style={{
            opacity: interpolate(termSpring, [0, 1], [0, 1]) * termDim,
            transform: `translateY(${interpolate(termSpring, [0, 1], [16, 0])}px)`,
          }}
        >
          <div style={{ color: colors.textDim, marginBottom: 8 }}>
            <span style={{ color: colors.blue }}>$</span> claude --goal GOAL.md
          </div>
          {frame > 15 && (
            <div style={{ color: colors.muted }}>
              Running improvement loop{frame < resultStart ? dots : ""}
            </div>
          )}
          {frame > 30 && frame < resultStart && (
            <div style={{ marginTop: 6 }}>
              <span style={{ color: colors.textDim }}>Score: </span>
              <span style={{ color: colors.red }}>47</span>
              <span style={{ color: colors.muted }}> {"\u2192"} </span>
              <span style={{ color: getScoreColor(Math.min(47 + Math.floor((frame - 30) / 3), 83)) }}>
                {Math.min(47 + Math.floor((frame - 30) / 3), 83)}
              </span>
            </div>
          )}
        </TerminalChrome>
      </div>

      {/* Clock */}
      {frame > clockStart && frame < resultStart + 20 && (
        <div
          style={{
            position: "absolute",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            opacity: clockOpacity * (frame > resultStart ? interpolate(frame, [resultStart, resultStart + 15], [1, 0], { extrapolateRight: "clamp" }) : 1),
            textAlign: "center",
          }}
        >
          <div style={{ ...heading, fontSize: FONT_SIZES.hero, letterSpacing: "-0.04em" }}>{clockTime}</div>
          <div style={{ ...sans, fontSize: 24, color: colors.muted, marginTop: 12, fontWeight: 400 }}>
            {hours < 2 ? "zzz" : hours < 5 ? "zzz..." : "zzz......"}
          </div>
        </div>
      )}

      {/* Result + CTA — vertically centered as a group */}
      {frame > resultStart && (
        <AbsoluteFill
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: `0 ${FRAME_PADDING}px`,
          }}
        >
          {/* Score result */}
          <div
            style={{
              textAlign: "center",
              opacity: interpolate(resultSpring, [0, 1], [0, 1]),
              transform: `scale(${interpolate(resultSpring, [0, 1], [0.92, 1])})`,
              marginBottom: frame > ctaStart ? 48 : 0,
            }}
          >
            <div style={{ ...sans, fontSize: FONT_SIZES.body, color: colors.textDim, fontWeight: 500, marginBottom: 16 }}>
              woke up to
            </div>
            <div style={{ ...heading, fontSize: 104, letterSpacing: "-0.04em" }}>
              <span style={{ color: colors.green }}>83</span>
              <span style={{ color: colors.muted, fontSize: 52 }}> / 100</span>
            </div>
            <div style={{ ...sans, fontSize: FONT_SIZES.body, color: colors.blue, fontWeight: 600, marginTop: 16 }}>
              12 atomic commits while you slept
            </div>
          </div>

          {/* CTA */}
          {frame > ctaStart && (
            <div
              style={{
                textAlign: "center",
                opacity: interpolate(ctaSpring, [0, 1], [0, 1]),
                transform: `translateY(${interpolate(ctaSpring, [0, 1], [16, 0])}px)`,
              }}
            >
              <div style={{ ...heading, fontSize: FONT_SIZES.subtitle, marginBottom: 24 }}>
                give it a number. go to sleep.
              </div>

              <div style={{
                ...mono,
                fontSize: 18,
                backgroundColor: colors.text,
                color: colors.bg,
                display: "inline-block",
                padding: "14px 32px",
                borderRadius: 8,
              }}>
                <span style={{ color: colors.amber }}>$</span> claude "Read goal-md and write me a GOAL.md"
              </div>

              <div style={{ ...mono, fontSize: FONT_SIZES.caption, color: colors.muted, marginTop: 16 }}>
                github.com/jmilinovich/goal-md
              </div>
            </div>
          )}
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};
