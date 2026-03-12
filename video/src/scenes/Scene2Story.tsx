import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { colors, mono, terminalContainer, heading, sans, FRAMES_PER_BEAT, FRAME_PADDING, centeredContent, FONT_SIZES } from "../styles";
import { TerminalChrome } from "../components/TerminalChrome";

const scoreSteps = [
  { score: 47, health: 0.42, accuracy: 0.61, coverage: 0.67, consistency: 0.38, commit: null },
  { score: 52, health: 0.55, accuracy: 0.61, coverage: 0.67, consistency: 0.42, commit: "Fix health-check route detection" },
  { score: 58, health: 0.55, accuracy: 0.71, coverage: 0.72, consistency: 0.48, commit: "Add accuracy tests for edge routes" },
  { score: 64, health: 0.68, accuracy: 0.75, coverage: 0.72, consistency: 0.55, commit: "Repair bidirectional link checks" },
  { score: 71, health: 0.72, accuracy: 0.80, coverage: 0.78, consistency: 0.62, commit: "Add coverage for auth middleware" },
  { score: 77, health: 0.78, accuracy: 0.85, coverage: 0.82, consistency: 0.68, commit: "Fix consistency in redirect tests" },
  { score: 83, health: 0.85, accuracy: 0.88, coverage: 0.85, consistency: 0.75, commit: "Add integration test for config pages" },
];

const getScoreColor = (s: number) => s >= 75 ? colors.green : s >= 60 ? colors.amber : colors.red;
const getValColor = (v: number) => v >= 0.7 ? colors.green : v >= 0.5 ? colors.amber : colors.red;

export const Scene2Story: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, config: { damping: 22, stiffness: 100 } });

  // Steps on a steady cadence
  const stepStart = FRAMES_PER_BEAT * 3;
  const framesPerStep = FRAMES_PER_BEAT * 3;
  const currentStep = Math.max(0, Math.min(scoreSteps.length - 1, Math.floor((frame - stepStart) / framesPerStep)));
  const step = scoreSteps[currentStep];

  const termSpring = spring({ frame: frame - FRAMES_PER_BEAT, fps, config: { damping: 20, stiffness: 80 } });

  const stepChangeFrame = stepStart + currentStep * framesPerStep;
  const scorePulse = spring({ frame: frame - stepChangeFrame, fps, config: { damping: 10, stiffness: 200, mass: 0.5 } });
  const scoreScale = frame > stepChangeFrame ? interpolate(scorePulse, [0, 0.5, 1], [1.08, 0.98, 1]) : 1;

  const commitSlide = step.commit
    ? spring({ frame: frame - stepChangeFrame - 8, fps, config: { damping: 18, stiffness: 100 } })
    : 0;

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {/* Title */}
      <div
        style={{
          ...centeredContent,
          ...heading,
          fontSize: FONT_SIZES.subtitle,
          top: 72,
          textAlign: "center",
          opacity: interpolate(titleSpring, [0, 1], [0, 1]),
          transform: `translateY(${interpolate(titleSpring, [0, 1], [10, 0])}px)`,
        }}
      >
        <span style={{ color: colors.textDim }}>I wrote a </span>
        <span style={{ color: colors.blue, fontWeight: 800 }}>GOAL.md</span>
        <span style={{ color: colors.textDim }}> and went to sleep</span>
      </div>

      {/* Lineage subtitle */}
      <div
        style={{
          ...centeredContent,
          ...sans,
          fontSize: FONT_SIZES.caption,
          top: 124,
          textAlign: "center",
          color: colors.muted,
          fontWeight: 400,
          opacity: interpolate(titleSpring, [0, 1], [0, 0.9]),
        }}
      >
        autoresearch generalized — constructed metrics, action catalog, keep/revert loop
      </div>

      {/* Score terminal */}
      <div
        style={{
          ...centeredContent,
          top: 160,
          display: "flex",
          justifyContent: "center",
        }}
      >
        <TerminalChrome
          width={680}
          style={{
            opacity: interpolate(termSpring, [0, 1], [0, 1]),
            transform: `translateY(${interpolate(termSpring, [0, 1], [16, 0])}px)`,
          }}
        >
          {/* Score display */}
          <div style={{ textAlign: "center", marginBottom: 20 }}>
            <div style={{ height: 1, backgroundColor: colors.border, marginBottom: 20 }} />
            <div style={{ transform: `scale(${scoreScale})`, display: "inline-block" }}>
              <span style={{ ...sans, fontSize: FONT_SIZES.label, color: colors.textDim, fontWeight: 500 }}>routing confidence </span>
              <span style={{ ...sans, fontSize: FONT_SIZES.subtitle, fontWeight: 800, color: getScoreColor(step.score) }}>
                {step.score}
              </span>
              <span style={{ ...sans, fontSize: FONT_SIZES.label, color: colors.muted }}> / 100</span>
            </div>
            <div style={{ height: 1, backgroundColor: colors.border, marginTop: 20 }} />
          </div>

          {/* Metrics */}
          {([
            ["health", step.health],
            ["accuracy", step.accuracy],
            ["coverage", step.coverage],
            ["consistency", step.consistency],
          ] as const).map(([name, val]) => (
            <div key={name} style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: 8,
              padding: "0 8px",
            }}>
              <span style={{ color: colors.textDim, fontSize: 16 }}>{name}</span>
              <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                <div style={{ width: 120, height: 4, backgroundColor: colors.border, borderRadius: 2, overflow: "hidden" }}>
                  <div style={{ width: `${(val as number) * 100}%`, height: "100%", backgroundColor: getValColor(val as number), borderRadius: 2 }} />
                </div>
                <span style={{ color: getValColor(val as number), fontWeight: 600, fontSize: 16, width: 36, textAlign: "right", ...mono }}>
                  {(val as number).toFixed(2)}
                </span>
              </div>
            </div>
          ))}
        </TerminalChrome>
      </div>

      {/* Commit ticker */}
      {step.commit && (
        <div
          style={{
            ...centeredContent,
            ...mono,
            bottom: 64,
            textAlign: "center",
            fontSize: FONT_SIZES.caption,
            opacity: interpolate(commitSlide as number, [0, 1], [0, 1]),
            transform: `translateX(${interpolate(commitSlide as number, [0, 1], [40, 0])}px)`,
          }}
        >
          <span style={{ color: colors.blue, fontWeight: 600 }}>commit </span>
          <span style={{ color: colors.textDim }}>{step.commit}</span>
        </div>
      )}

      {/* Counter */}
      <div style={{
        position: "absolute",
        bottom: 36,
        right: FRAME_PADDING,
        ...mono,
        fontSize: FONT_SIZES.small,
        color: colors.muted,
      }}>
        {currentStep > 0 && `${currentStep}/12 commits`}
      </div>
    </AbsoluteFill>
  );
};
